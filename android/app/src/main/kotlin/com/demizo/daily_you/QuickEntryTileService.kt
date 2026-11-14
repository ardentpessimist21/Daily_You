// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

package com.demizo.daily_you

import android.annotation.SuppressLint
import android.app.Activity
import android.app.PendingIntent
import android.app.StatusBarManager
import android.content.ComponentName
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

/** The "Quick entry" Quick Settings tile (Update Q). Works on the lock screen. */
@RequiresApi(Build.VERSION_CODES.N)
class QuickEntryTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            label = "Quick entry"
            updateTile()
        }
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    override fun onClick() {
        super.onClick()
        val intent = QuickEntry.sheetIntent(this)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                PendingIntent.getActivity(
                    this, 43, intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    companion object {
        /** Android 13+: asks to add the tile. False when the phone can't ask. */
        fun requestAdd(activity: Activity): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return false
            val statusBar = activity.getSystemService(StatusBarManager::class.java) ?: return false
            return try {
                statusBar.requestAddTileService(
                    ComponentName(activity, QuickEntryTileService::class.java),
                    "Quick entry",
                    Icon.createWithResource(activity, R.drawable.ic_quick_entry),
                    activity.mainExecutor
                ) { }
                true
            } catch (_: Exception) {
                false
            }
        }
    }
}
