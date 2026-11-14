// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

package com.demizo.daily_you

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
  // Quick entry (Update Q): the sheet's "Open full editor" and the pinned
  // notification's state
  private var quickEntryChannel: MethodChannel? = null
  private var pendingOpenId: Int? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    takeOpenRequest(intent)
    super.onCreate(savedInstanceState)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    quickEntryChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, QuickEntry.HOST_CHANNEL)
      .also { it.setMethodCallHandler { call, result ->
        when (call.method) {
          "updateNotification" -> {
            QuickEntryNotifier.update(
              this,
              call.argument<Boolean>("enabled") ?: false,
              call.argument<String>("lastLabel")
            )
            result.success(null)
          }
          "consumeOpenRequest" -> {
            result.success(pendingOpenId)
            pendingOpenId = null
          }
          "addShortcut" -> {
            QuickEntry.addShortcut(this)
            result.success(null)
          }
          "requestTile" -> result.success(QuickEntryTileService.requestAdd(this))
          else -> result.notImplemented()
        }
      } }
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    if (takeOpenRequest(intent)) quickEntryChannel?.invokeMethod("openRequest", null)
  }

  private fun takeOpenRequest(intent: Intent?): Boolean {
    if (intent?.action != QuickEntry.ACTION_OPEN) return false
    // Reopened from recents: Android replays the old intent
    if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return false
    pendingOpenId = intent.getIntExtra(QuickEntry.EXTRA_OPEN_ID, -1)
    intent.action = Intent.ACTION_MAIN
    return true
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
  }
}
