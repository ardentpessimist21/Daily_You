// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

package com.demizo.daily_you

import android.content.Context
import android.content.Intent
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/** Shared bits of Quick entry (Update Q). */
object QuickEntry {
    const val ACTION_SHEET = "com.demizo.daily_you.QUICK_ENTRY"
    const val ACTION_OPEN = "com.demizo.daily_you.OPEN_FROM_QUICK_ENTRY"
    const val EXTRA_OPEN_ID = "quickEntryOpenId"

    const val SHEET_CHANNEL = "daily_you/quick_entry"
    const val HOST_CHANNEL = "daily_you/quick_entry_host"
    const val REPLY_CHANNEL = "daily_you/quick_reply"

    /** The daily reminder's notification id (see lib/main.dart). */
    const val REMINDER_NOTIFICATION_ID = 0

    /** Opens the quick-entry sheet in its own window. */
    fun sheetIntent(context: Context): Intent =
        Intent(context, QuickEntryActivity::class.java)
            .setAction(ACTION_SHEET)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

    /** "Quick note" in the app icon's long-press menu. */
    fun addShortcut(context: Context) {
        val shortcut = ShortcutInfoCompat.Builder(context, "quick_note")
            .setShortLabel("Quick note")
            .setLongLabel("Quick note")
            .setIcon(IconCompat.createWithResource(context, R.drawable.ic_shortcut_edit))
            .setIntent(sheetIntent(context))
            .build()
        try {
            ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)
        } catch (_: Exception) {
        }
    }
}

/**
 * Notification replies waiting to be saved. Kept where the app's Dart side
 * reads its settings (SharedPreferences "flutter.quickEntryQueue"), so a
 * reply is saved even if the quick save below doesn't finish.
 */
object QuickEntryQueue {
    private const val FILE = "FlutterSharedPreferences"
    private const val KEY = "flutter.quickEntryQueue"

    @Synchronized
    fun add(context: Context, text: String, target: String) {
        val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
        val queue = try {
            JSONArray(prefs.getString(KEY, null) ?: "[]")
        } catch (_: Exception) {
            JSONArray()
        }
        queue.put(
            JSONObject()
                .put("id", UUID.randomUUID().toString())
                .put("text", text)
                .put("target", target)
                .put("at", System.currentTimeMillis())
        )
        prefs.edit().putString(KEY, queue.toString()).commit()
    }

    fun hasWaiting(context: Context): Boolean {
        val raw = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            .getString(KEY, null) ?: return false
        return try {
            JSONArray(raw).length() > 0
        } catch (_: Exception) {
            false
        }
    }
}
