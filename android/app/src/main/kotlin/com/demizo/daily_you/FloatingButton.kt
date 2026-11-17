// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

package com.demizo.daily_you

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import java.util.Calendar
import java.util.Random

/**
 * Update F: the floating button's settings and state, kept on the Android
 * side so the button works without the Flutter app running.
 *
 * Settings come from Settings › Journal › Quick entry (lib/fork/quick_entry/
 * quick_entry_settings.dart) through [apply].
 */
object FloatingButton {
    const val ACTION_SHOW = "com.demizo.daily_you.FLOATING_SHOW"

    private const val PREFS = "daily_you_floating_button"

    // Settings
    private const val ENABLED = "enabled"
    private const val OPACITY = "opacity"
    private const val HIDE_DND = "hideDnd"
    private const val BRING_BACK = "bringBack"
    private const val BADGE = "badge"
    private const val BADGE_TIMES = "badgeTimes"
    private const val BADGE_MODE = "badgeMode"
    private const val BADGE_START = "badgeStart"
    private const val BADGE_END = "badgeEnd"
    private const val NUDGE = "nudge"

    // State
    private const val SIDE_RIGHT = "sideRight"
    private const val Y_FRACTION = "yFraction"
    private const val USER_HIDDEN = "userHidden"
    private const val HIDDEN_UNTIL = "hiddenUntil"
    private const val WAIT_UNLOCK = "waitUnlock"
    private const val DOT = "dot"
    private const val PLAN_DAY = "planDay"
    private const val PLAN = "plan"
    private const val PLAN_DONE = "planDone"

    /** Nudges are at least this far apart. */
    const val MIN_GAP_MINUTES = 30
    const val MAX_TIMES = 10

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun isEnabled(context: Context) = prefs(context).getBoolean(ENABLED, false)
    fun isUserHidden(context: Context) = prefs(context).getBoolean(USER_HIDDEN, false)

    fun canDrawOverlays(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)

    /** Opens Android's "Display over other apps" page for Daily You. */
    fun overlaySettingsIntent(context: Context): Intent =
        Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:" + context.packageName)
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

    /** Settings from the app. Starts, updates or stops the button. */
    fun apply(context: Context, config: Map<*, *>) {
        val prefs = prefs(context)
        val wasEnabled = prefs.getBoolean(ENABLED, false)
        val oldPlanKey = planSettingsKey(prefs)
        prefs.edit().apply {
            putBoolean(ENABLED, config["enabled"] == true)
            putInt(OPACITY, ((config["opacity"] as? Number)?.toInt() ?: 80).coerceIn(30, 100))
            putBoolean(HIDE_DND, config["hideDnd"] != false)
            putString(BRING_BACK, config["bringBack"] as? String ?: "unlock")
            putBoolean(BADGE, config["badge"] != false)
            putInt(BADGE_TIMES, ((config["badgeTimes"] as? Number)?.toInt() ?: 1).coerceIn(1, MAX_TIMES))
            putString(BADGE_MODE, config["badgeMode"] as? String ?: "random")
            putInt(BADGE_START, ((config["badgeStart"] as? Number)?.toInt() ?: 9 * 60).coerceIn(0, 24 * 60 - 1))
            putInt(BADGE_END, ((config["badgeEnd"] as? Number)?.toInt() ?: 21 * 60).coerceIn(0, 24 * 60 - 1))
            putBoolean(NUDGE, config["nudge"] != false)
            apply()
        }
        // A changed badge setting makes a new plan for today
        if (planSettingsKey(prefs) != oldPlanKey) {
            prefs.edit().remove(PLAN_DAY).apply()
        }
        val enabled = prefs.getBoolean(ENABLED, false)
        if (enabled && !wasEnabled) {
            // Turning it on shows it, whatever was hidden before
            prefs.edit().putBoolean(USER_HIDDEN, false).remove(HIDDEN_UNTIL)
                .remove(WAIT_UNLOCK).apply()
        }
        if (enabled && canDrawOverlays(context)) {
            start(context)
        } else {
            stop(context)
        }
        QuickEntryNotifier.repost(context)
    }

    /** After a restart or an app update. */
    fun restore(context: Context) {
        if (isEnabled(context) && canDrawOverlays(context)) start(context)
    }

    fun start(context: Context) {
        val intent = Intent(context, FloatingButtonService::class.java)
        try {
            ContextCompat.startForegroundService(context, intent)
        } catch (_: Exception) {
            // Not allowed from the background right now; it starts with the app
        }
    }

    fun stop(context: Context) {
        FloatingButtonService.instance?.stopSelf()
        context.stopService(Intent(context, FloatingButtonService::class.java))
    }

    // Reading settings

    fun opacity(context: Context) = prefs(context).getInt(OPACITY, 80) / 100f
    fun hideDuringDnd(context: Context) = prefs(context).getBoolean(HIDE_DND, true)
    fun nudge(context: Context) = prefs(context).getBoolean(NUDGE, true)

    // Position

    fun sideRight(context: Context) = prefs(context).getBoolean(SIDE_RIGHT, true)
    fun yFraction(context: Context) = prefs(context).getFloat(Y_FRACTION, 0.4f)
    fun savePosition(context: Context, right: Boolean, yFraction: Float) {
        prefs(context).edit().putBoolean(SIDE_RIGHT, right)
            .putFloat(Y_FRACTION, yFraction.coerceIn(0f, 1f)).apply()
    }

    // Hiding with ✕

    /** Hidden by dragging to ✕, until the "Bring back after" choice. */
    fun hideByUser(context: Context) {
        val prefs = prefs(context)
        val now = System.currentTimeMillis()
        val edit = prefs.edit().putBoolean(USER_HIDDEN, true).remove(HIDDEN_UNTIL).remove(WAIT_UNLOCK)
        when (prefs.getString(BRING_BACK, "unlock")) {
            "30m" -> edit.putLong(HIDDEN_UNTIL, now + 30 * 60_000L)
            "1h" -> edit.putLong(HIDDEN_UNTIL, now + 60 * 60_000L)
            "tomorrow" -> {
                val start = prefs.getInt(BADGE_START, 9 * 60)
                val cal = Calendar.getInstance().apply {
                    add(Calendar.DAY_OF_YEAR, 1)
                    set(Calendar.HOUR_OF_DAY, start / 60)
                    set(Calendar.MINUTE, start % 60)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                edit.putLong(HIDDEN_UNTIL, cal.timeInMillis)
            }
            "never" -> {}
            else -> edit.putBoolean(WAIT_UNLOCK, true)
        }
        edit.apply()
        QuickEntryNotifier.repost(context)
    }

    fun showByUser(context: Context) {
        prefs(context).edit().putBoolean(USER_HIDDEN, false).remove(HIDDEN_UNTIL)
            .remove(WAIT_UNLOCK).apply()
        QuickEntryNotifier.repost(context)
    }

    /** Milliseconds until a timed hide ends, or null when it isn't timed. */
    fun hiddenUntil(context: Context): Long? {
        val prefs = prefs(context)
        if (!prefs.getBoolean(USER_HIDDEN, false) || !prefs.contains(HIDDEN_UNTIL)) return null
        return prefs.getLong(HIDDEN_UNTIL, 0)
    }

    /** Ends a hide whose time has come; true when it did. */
    fun endTimedHideIfDue(context: Context): Boolean {
        val until = hiddenUntil(context) ?: return false
        if (System.currentTimeMillis() < until) return false
        showByUser(context)
        return true
    }

    /** "Next unlock": the phone was unlocked. */
    fun onUnlocked(context: Context): Boolean {
        val prefs = prefs(context)
        if (!prefs.getBoolean(USER_HIDDEN, false) || !prefs.getBoolean(WAIT_UNLOCK, false)) return false
        showByUser(context)
        return true
    }

    // Badge

    fun hasDot(context: Context) = prefs(context).getBoolean(DOT, false)
    fun setDot(context: Context, on: Boolean) {
        prefs(context).edit().putBoolean(DOT, on).apply()
    }

    private fun planSettingsKey(prefs: SharedPreferences) = listOf(
        prefs.getBoolean(BADGE, true), prefs.getInt(BADGE_TIMES, 1),
        prefs.getString(BADGE_MODE, "random"), prefs.getInt(BADGE_START, 540),
        prefs.getInt(BADGE_END, 1260)
    ).joinToString("|")

    private fun dayKey(cal: Calendar = Calendar.getInstance()) =
        "%04d-%02d-%02d".format(
            cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH)
        )

    private fun minuteOfDay(cal: Calendar = Calendar.getInstance()) =
        cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)

    /** How many nudges fit in a range at least [MIN_GAP_MINUTES] apart. */
    fun maxTimesFor(startMinute: Int, endMinute: Int): Int {
        val length = endMinute - startMinute
        if (length <= 0) return 1
        return (length / MIN_GAP_MINUTES + 1).coerceIn(1, MAX_TIMES)
    }

    /** Today's nudge times (minutes of the day), made once a day. */
    private fun todaysPlan(context: Context): List<Int> {
        val prefs = prefs(context)
        val today = dayKey()
        if (prefs.getString(PLAN_DAY, null) == today) {
            return prefs.getString(PLAN, "")!!.split(',').mapNotNull { it.toIntOrNull() }
        }
        val plan = makePlan(prefs)
        prefs.edit()
            .putString(PLAN_DAY, today)
            .putString(PLAN, plan.joinToString(","))
            .putInt(PLAN_DONE, 0)
            // Yesterday's dot doesn't carry over
            .putBoolean(DOT, false)
            .apply()
        return plan
    }

    private fun makePlan(prefs: SharedPreferences): List<Int> {
        if (!prefs.getBoolean(BADGE, true)) return emptyList()
        val start = prefs.getInt(BADGE_START, 9 * 60)
        val end = prefs.getInt(BADGE_END, 21 * 60)
        if (end <= start) return listOf(start)
        val times = prefs.getInt(BADGE_TIMES, 1).coerceAtMost(maxTimesFor(start, end))
        val length = end - start
        if (prefs.getString(BADGE_MODE, "random") == "fixed") {
            // Spread evenly, starting at the start of the range
            return (0 until times).map { start + it * length / times }
        }
        // Random, at least MIN_GAP_MINUTES apart: pick from the slack, then
        // add the gaps back in
        val slack = length - (times - 1) * MIN_GAP_MINUTES
        val random = Random()
        val picks = (0 until times).map { random.nextInt(slack + 1) }.sorted()
        return picks.mapIndexed { index, pick -> start + pick + index * MIN_GAP_MINUTES }
    }

    /**
     * Counts nudges whose time has come. Returns how many are new since the
     * last check (0 when none), so the button can show the dot and wiggle.
     */
    fun takeDueNudges(context: Context): Int {
        val plan = todaysPlan(context)
        val prefs = prefs(context)
        val now = minuteOfDay()
        val due = plan.count { it <= now }
        val done = prefs.getInt(PLAN_DONE, 0)
        if (due <= done) return 0
        prefs.edit().putInt(PLAN_DONE, due).putBoolean(DOT, true).apply()
        return due - done
    }

    /** Milliseconds until the next nudge today, or null when there's none left. */
    fun millisToNextNudge(context: Context): Long? {
        val plan = todaysPlan(context)
        val cal = Calendar.getInstance()
        val nowMinute = minuteOfDay(cal)
        val next = plan.firstOrNull { it > nowMinute } ?: return null
        val secondsNow = cal.get(Calendar.SECOND)
        return ((next - nowMinute) * 60L - secondsNow) * 1000L
    }
}

/** "Show floating button" in the notification. */
class FloatingActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != FloatingButton.ACTION_SHOW) return
        val app = context.applicationContext
        FloatingButton.showByUser(app)
        val service = FloatingButtonService.instance
        if (service != null) service.refresh() else FloatingButton.restore(app)
    }
}
