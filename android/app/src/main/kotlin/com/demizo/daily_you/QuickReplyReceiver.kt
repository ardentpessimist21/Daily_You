// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

package com.demizo.daily_you

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.RemoteInput
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/** A reply typed into the notification (Update Q). */
class QuickReplyReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        val text = RemoteInput.getResultsFromIntent(intent)
            ?.getCharSequence(QuickEntryNotifier.KEY_TEXT)?.toString()?.trim()
        if (text.isNullOrEmpty()) {
            QuickEntryNotifier.repost(app)
            return
        }
        val target = intent.getStringExtra(QuickEntryNotifier.EXTRA_TARGET) ?: "new"

        // Written down first, so nothing is lost if the save below can't finish
        QuickEntryQueue.add(app, text, target)
        QuickEntryNotifier.afterSave(app, null, "Saving…")

        val pending = goAsync()
        QuickReplyRunner.run(app) { status ->
            val failed = status?.get("failed") == true
            val message = status?.get("message") as? String
            if (!failed) {
                NotificationManagerCompat.from(app).cancel(QuickEntry.REMINDER_NOTIFICATION_ID)
            }
            QuickEntryNotifier.afterSave(
                app,
                status?.get("lastLabel") as? String,
                message?.let { if (failed) it else "✓ $it" }
            )
            pending.finish()
        }
    }
}

/**
 * Saves waiting replies in a short-lived, windowless Flutter engine running
 * quickReplyMain (lib/main.dart), so the save goes through the app's own code.
 */
object QuickReplyRunner {
    private const val TIMEOUT_MS = 20_000L

    private val main = Handler(Looper.getMainLooper())
    private var engine: FlutterEngine? = null
    private val callbacks = mutableListOf<(Map<*, *>?) -> Unit>()
    private var timeout: Runnable? = null

    fun run(context: Context, onDone: (Map<*, *>?) -> Unit) {
        main.post {
            callbacks.add(onDone)
            if (engine == null) start(context)
        }
    }

    private fun start(context: Context) {
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(context)
            loader.ensureInitializationComplete(context, null)
            val newEngine = FlutterEngine(context)
            engine = newEngine
            MethodChannel(newEngine.dartExecutor.binaryMessenger, QuickEntry.REPLY_CHANNEL)
                .setMethodCallHandler { call, result ->
                    if (call.method == "done") {
                        result.success(null)
                        val status = call.arguments as? Map<*, *>
                        main.post { finish(context, status) }
                    } else {
                        result.notImplemented()
                    }
                }
            val stop = Runnable {
                finish(
                    context,
                    mapOf("message" to "Saved for later. Open Daily You to finish", "failed" to true)
                )
            }
            timeout = stop
            main.postDelayed(stop, TIMEOUT_MS)
            newEngine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "quickReplyMain")
            )
        } catch (error: Throwable) {
            finish(
                context,
                mapOf("message" to "Saved for later. Open Daily You to finish", "failed" to true)
            )
        }
    }

    private fun finish(context: Context, status: Map<*, *>?) {
        timeout?.let { main.removeCallbacks(it) }
        timeout = null
        try {
            engine?.destroy()
        } catch (_: Throwable) {
        }
        engine = null
        val waiting = callbacks.toList()
        callbacks.clear()
        waiting.forEach { it(status) }
        // A reply that came in while saving: run again for it
        if (status?.get("failed") != true && QuickEntryQueue.hasWaiting(context)) {
            run(context) { later ->
                QuickEntryNotifier.afterSave(
                    context,
                    later?.get("lastLabel") as? String,
                    (later?.get("message") as? String)?.let { "✓ $it" }
                )
            }
        }
    }
}
