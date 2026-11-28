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

    /** The floating button's Daily You › Search: Gallery, ready to type (3.7.0.68). */
    const val ACTION_SEARCH = "com.demizo.daily_you.GALLERY_SEARCH"
    const val EXTRA_OPEN_ID = "quickEntryOpenId"

    const val SHEET_CHANNEL = "daily_you/quick_entry"
    const val HOST_CHANNEL = "daily_you/quick_entry_host"
    const val REPLY_CHANNEL = "daily_you/quick_reply"

    /** The daily reminder's notification id (see lib/main.dart). */
    const val REMINDER_NOTIFICATION_ID = 0

    const val EXTRA_CAPTURE = "quickEntryCapture"

    /**
     * Opens the quick-entry sheet in its own window; [capture] ("photo",
     * "video" or "audio", from the floating button's pie) starts that first.
     */
    fun sheetIntent(context: Context, capture: String? = null): Intent =
        Intent(context, QuickEntryActivity::class.java)
            .setAction(ACTION_SHEET)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .apply { if (capture != null) putExtra(EXTRA_CAPTURE, capture) }

    /**
     * Asks the camera app to start on the front or back lens (3.7.0.69).
     * There's no standard way, so this sends every request camera apps are
     * known to read, Samsung's included; the camera may still ignore them.
     */
    fun putLens(intent: Intent, front: Boolean) {
        val legacy = if (front) 1 else 0 // Camera.CameraInfo numbering
        intent.putExtra("android.intent.extras.CAMERA_FACING", legacy)
        intent.putExtra("android.intent.extras.LENS_FACING_FRONT", if (front) 1 else 0)
        intent.putExtra("android.intent.extras.LENS_FACING_BACK", if (front) 0 else 1)
        intent.putExtra("android.intent.extra.USE_FRONT_CAMERA", front)
        intent.putExtra("com.google.assistant.extra.USE_FRONT_CAMERA", front)
        intent.putExtra("camerafacing", if (front) "front" else "rear")
        intent.putExtra("previous_mode", if (front) "front" else "rear")
        intent.putExtra("default_camera", if (front) "1" else "0")
        intent.putExtra("android.intent.extras.CAMERA_ID", legacy)
    }

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
