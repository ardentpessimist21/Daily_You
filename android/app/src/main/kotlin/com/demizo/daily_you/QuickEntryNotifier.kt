// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

package com.demizo.daily_you

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.RemoteInput
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * The pinned "Add to Daily You" notification (Update Q): tap to open the
 * quick-entry sheet, or reply right in it as a new entry or added to today's
 * last entry ("Add to last entry" only shows when there is one).
 */
object QuickEntryNotifier {
    const val CHANNEL_ID = "daily_you_quick_entry"
    const val NOTIFICATION_ID = 4210
    const val KEY_TEXT = "quick_entry_text"
    const val EXTRA_TARGET = "quick_entry_target"

    private const val PREFS = "daily_you_quick_entry"
    private const val ENABLED = "enabled"
    private const val LAST_LABEL = "lastLabel"
    private const val LAST_DAY = "lastDay"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun today(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

    fun isEnabled(context: Context) = prefs(context).getBoolean(ENABLED, false)

    /** From the app: turn on or off, and today's last entry time (or null). */
    fun update(context: Context, enabled: Boolean, lastLabel: String?) {
        prefs(context).edit()
            .putBoolean(ENABLED, enabled)
            .putString(LAST_LABEL, lastLabel)
            .putString(LAST_DAY, today())
            .apply()
        if (enabled) post(context) else cancel(context)
    }

    /** After a save: there's an entry today now. */
    fun afterSave(context: Context, lastLabel: String?, status: String?) {
        if (lastLabel != null) {
            prefs(context).edit()
                .putString(LAST_LABEL, lastLabel)
                .putString(LAST_DAY, today())
                .apply()
        }
        if (isEnabled(context)) post(context, status)
    }

    /** After a restart or an app update. */
    fun repost(context: Context) {
        if (isEnabled(context)) post(context)
    }

    fun cancel(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    /** Today's last entry time, or null when the last one saved isn't from today. */
    private fun lastLabelToday(context: Context): String? {
        val prefs = prefs(context)
        if (prefs.getString(LAST_DAY, null) != today()) return null
        return prefs.getString(LAST_LABEL, null)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        // Default importance so it shows on the lock screen, but no sound
        // or vibration: it never alerts.
        val channel = NotificationChannel(
            CHANNEL_ID, "Quick entry", NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Add a note from the lock screen or any app"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    fun post(context: Context, status: String? = null) {
        ensureChannel(context)
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return

        val open = PendingIntent.getActivity(
            context, 40, QuickEntry.sheetIntent(context),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val last = lastLabelToday(context)

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Add to Daily You")
            .setContentText(status ?: "Tap to open, or reply right here")
            .setContentIntent(open)
            .setOngoing(true)
            .setAutoCancel(false)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(replyAction(context, "new", "New entry", "New entry for today"))
        if (last != null) {
            builder.addAction(
                replyAction(context, "last", "Add to last entry", "Add to the $last entry")
            )
        }
        try {
            manager.notify(NOTIFICATION_ID, builder.build())
        } catch (_: SecurityException) {
            // Notifications not allowed
        }
    }

    private fun replyAction(
        context: Context, target: String, title: String, hint: String
    ): NotificationCompat.Action {
        val input = RemoteInput.Builder(KEY_TEXT).setLabel(hint).build()
        val intent = Intent(context, QuickReplyReceiver::class.java)
            .setAction("com.demizo.daily_you.QUICK_REPLY_$target")
            .putExtra(EXTRA_TARGET, target)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0)
        val pending = PendingIntent.getBroadcast(
            context, if (target == "last") 42 else 41, intent, flags
        )
        return NotificationCompat.Action.Builder(R.drawable.ic_quick_entry, title, pending)
            .addRemoteInput(input)
            .setAllowGeneratedReplies(false)
            .setShowsUserInterface(false)
            .build()
    }
}
