// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

package com.demizo.daily_you

import android.app.KeyguardManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.Toast
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The quick-entry sheet (Update Q): a see-through window over whatever app
 * is open, or over the lock screen, running quickEntryMain (lib/main.dart).
 * Opened from the notification, the Quick Settings tile, the widget, the
 * app icon's "Quick note", or "Add to Daily You" on selected text.
 */
class QuickEntryActivity : FlutterFragmentActivity() {
    private var channel: MethodChannel? = null
    private var launchText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        }
        launchText = textFrom(intent)
        super.onCreate(savedInstanceState)
    }

    override fun getDartEntrypointFunctionName(): String = "quickEntryMain"

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, QuickEntry.SHEET_CHANNEL)
            .also { it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLaunch" -> {
                        result.success(mapOf("text" to launchText, "locked" to isLocked()))
                        launchText = null
                    }
                    "requestUnlock" -> requestUnlock(result)
                    "saved" -> {
                        NotificationManagerCompat.from(this)
                            .cancel(QuickEntry.REMINDER_NOTIFICATION_ID)
                        QuickEntryNotifier.afterSave(this, call.argument<String>("lastLabel"), null)
                        result.success(null)
                    }
                    "close" -> {
                        result.success(null)
                        call.argument<String>("message")?.let {
                            Toast.makeText(applicationContext, it, Toast.LENGTH_SHORT).show()
                        }
                        close()
                    }
                    "openInApp" -> {
                        result.success(null)
                        val id = call.argument<Int>("id") ?: -1
                        startActivity(
                            Intent(this, MainActivity::class.java)
                                .setAction(QuickEntry.ACTION_OPEN)
                                .putExtra(QuickEntry.EXTRA_OPEN_ID, id)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        close()
                    }
                    else -> result.notImplemented()
                }
            } }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        channel?.invokeMethod(
            "launch", mapOf("text" to textFrom(intent), "locked" to isLocked())
        )
    }

    private fun textFrom(intent: Intent?): String? {
        if (intent == null) return null
        return when (intent.action) {
            Intent.ACTION_PROCESS_TEXT ->
                intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
            else -> intent.getStringExtra(Intent.EXTRA_TEXT)
        }
    }

    private fun isLocked(): Boolean =
        getSystemService(KeyguardManager::class.java)?.isKeyguardLocked == true

    private fun requestUnlock(result: MethodChannel.Result) {
        if (!isLocked()) {
            result.success(true)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(false)
            return
        }
        val keyguard = getSystemService(KeyguardManager::class.java)
        if (keyguard == null) {
            result.success(false)
            return
        }
        var answered = false
        fun answer(value: Boolean) {
            if (answered) return
            answered = true
            result.success(value)
        }
        keyguard.requestDismissKeyguard(this, object : KeyguardManager.KeyguardDismissCallback() {
            override fun onDismissSucceeded() = answer(true)
            override fun onDismissCancelled() = answer(false)
            override fun onDismissError() = answer(false)
        })
    }

    private fun close() {
        finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, android.R.anim.fade_out)
    }
}
