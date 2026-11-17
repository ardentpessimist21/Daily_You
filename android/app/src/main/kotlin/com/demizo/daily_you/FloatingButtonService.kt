// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

package com.demizo.daily_you

import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Outline
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewOutlineProvider
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import kotlin.math.abs
import kotlin.math.hypot

/**
 * Update F: the floating button. The Daily You app icon, tucked half
 * off-screen at the left or right edge, over other apps. Tap it for the
 * quick-entry sheet; drag it anywhere and it tucks into the nearest edge;
 * drop it on ✕ to hide it until the "Bring back after" choice.
 *
 * It hides inside Daily You, while the sheet is open, and (by default)
 * during Do Not Disturb. A red dot appears at the badge's random times, with a
 * small wiggle (Nudge); tapping the button clears it.
 *
 * Android only keeps it alive with a notification, so it runs as a foreground
 * service showing the pinned quick-entry notification.
 */
class FloatingButtonService : Service() {

    companion object {
        @SuppressLint("StaticFieldLeak")
        @Volatile
        var instance: FloatingButtonService? = null
            private set

        /** Daily You's own screens are showing (the button hides). */
        @Volatile
        var hostVisible = false
            set(value) {
                field = value
                instance?.let { it.handler.post { it.refresh() } }
            }

        /** The quick-entry sheet is open (the button hides). */
        @Volatile
        var sheetOpen = false
            set(value) {
                field = value
                instance?.let { it.handler.post { it.refresh() } }
            }

        private const val BUTTON_DP = 52
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var windowManager: WindowManager

    private var root: FrameLayout? = null
    private var icon: ImageView? = null
    private var dot: View? = null
    private var params: WindowManager.LayoutParams? = null
    private var attached = false

    private var target: FrameLayout? = null
    private var targetAttached = false

    private var dndOn = false
    private var snapAnimator: ValueAnimator? = null

    private val nudgeCheck = Runnable { checkNudges() }
    private val hideTimer = Runnable {
        if (FloatingButton.endTimedHideIfDue(this)) refresh() else scheduleHideTimer()
    }

    private val events = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_USER_PRESENT -> {
                    FloatingButton.onUnlocked(this@FloatingButtonService)
                    FloatingButton.endTimedHideIfDue(this@FloatingButtonService)
                    checkNudges()
                    refresh()
                }
                Intent.ACTION_SCREEN_ON -> {
                    FloatingButton.endTimedHideIfDue(this@FloatingButtonService)
                    checkNudges()
                }
                NotificationManager.ACTION_INTERRUPTION_FILTER_CHANGED -> {
                    readDnd()
                    refresh()
                }
            }
        }
    }

    // Lifecycle

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        windowManager = getSystemService(WindowManager::class.java)
        goForeground()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_USER_PRESENT)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(NotificationManager.ACTION_INTERRUPTION_FILTER_CHANGED)
        }
        ContextCompat.registerReceiver(this, events, filter, ContextCompat.RECEIVER_EXPORTED)
        readDnd()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        goForeground()
        if (!FloatingButton.isEnabled(this) || !FloatingButton.canDrawOverlays(this)) {
            stopSelf()
            return START_NOT_STICKY
        }
        checkNudges()
        refresh()
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        try {
            unregisterReceiver(events)
        } catch (_: Exception) {
        }
        removeTarget()
        removeButton()
        if (instance === this) instance = null
        // The notification stays only if it's switched on by itself
        ServiceCompat.stopForeground(
            this,
            if (QuickEntryNotifier.isEnabled(this)) ServiceCompat.STOP_FOREGROUND_DETACH
            else ServiceCompat.STOP_FOREGROUND_REMOVE
        )
        super.onDestroy()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        // Rotated: tuck back into the same edge at the same height
        handler.post { placeAtSavedPosition() }
    }

    private fun goForeground() {
        val notification = QuickEntryNotifier.build(this)
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
        } else {
            0
        }
        try {
            ServiceCompat.startForeground(this, QuickEntryNotifier.NOTIFICATION_ID, notification, type)
        } catch (_: Exception) {
            stopSelf()
        }
    }

    // Showing and hiding

    private fun readDnd() {
        val manager = getSystemService(NotificationManager::class.java)
        dndOn = manager != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            manager.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL &&
            manager.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_UNKNOWN
    }

    private fun shouldShow(): Boolean {
        if (!FloatingButton.isEnabled(this)) return false
        if (FloatingButton.isUserHidden(this)) return false
        if (dndOn && FloatingButton.hideDuringDnd(this)) return false
        if (hostVisible || sheetOpen) return false
        return true
    }

    /** Puts the button up or takes it down, and updates its look. */
    fun refresh() {
        if (!FloatingButton.canDrawOverlays(this)) {
            removeButton()
            return
        }
        if (shouldShow()) {
            addButton()
            root?.alpha = FloatingButton.opacity(this)
            updateDot()
        } else {
            removeButton()
        }
        scheduleHideTimer()
        scheduleNudgeCheck()
    }

    private fun dp(value: Int): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), resources.displayMetrics
    ).toInt()

    private fun overlayType(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

    private fun screenWidth(): Int = resources.displayMetrics.widthPixels
    private fun screenHeight(): Int = resources.displayMetrics.heightPixels

    @SuppressLint("ClickableViewAccessibility")
    private fun addButton() {
        if (attached) return
        val size = dp(BUTTON_DP)
        val frame = FrameLayout(this)
        val image = ImageView(this).apply {
            setImageDrawable(packageManager.getApplicationIcon(packageName))
            scaleType = ImageView.ScaleType.CENTER_CROP
            outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setOval(0, 0, view.width, view.height)
                }
            }
            clipToOutline = true
            elevation = dp(6).toFloat()
            contentDescription = "Quick entry"
        }
        frame.addView(image, FrameLayout.LayoutParams(size, size))
        val badge = View(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#FF5449"))
                setStroke(dp(2), Color.WHITE)
            }
            elevation = dp(8).toFloat()
            visibility = View.GONE
        }
        frame.addView(badge, FrameLayout.LayoutParams(dp(14), dp(14)))

        val layout = WindowManager.LayoutParams(
            size, size, overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.TOP or Gravity.START }

        frame.setOnTouchListener(DragListener())

        try {
            windowManager.addView(frame, layout)
        } catch (_: Exception) {
            // Permission taken away
            return
        }
        root = frame
        icon = image
        dot = badge
        params = layout
        attached = true
        placeAtSavedPosition()
    }

    private fun removeButton() {
        snapAnimator?.cancel()
        if (attached) {
            try {
                windowManager.removeView(root)
            } catch (_: Exception) {
            }
        }
        attached = false
        root = null
        icon = null
        dot = null
        params = null
    }

    /** Half off-screen at the saved edge and height. */
    private fun placeAtSavedPosition() {
        val layout = params ?: return
        val size = dp(BUTTON_DP)
        val right = FloatingButton.sideRight(this)
        layout.x = tuckedX(right)
        val usable = (screenHeight() - size).coerceAtLeast(1)
        layout.y = (FloatingButton.yFraction(this) * usable).toInt()
        updateLayout()
        positionDot(right)
    }

    private fun tuckedX(right: Boolean): Int {
        val size = dp(BUTTON_DP)
        return if (right) screenWidth() - size / 2 else -size / 2
    }

    private fun updateLayout() {
        val frame = root ?: return
        val layout = params ?: return
        try {
            windowManager.updateViewLayout(frame, layout)
        } catch (_: Exception) {
        }
    }

    /** The dot sits on the half that shows. */
    private fun positionDot(right: Boolean) {
        val badge = dot ?: return
        val lp = badge.layoutParams as FrameLayout.LayoutParams
        lp.gravity = Gravity.TOP or (if (right) Gravity.START else Gravity.END)
        lp.leftMargin = if (right) dp(3) else 0
        lp.rightMargin = if (right) 0 else dp(3)
        lp.topMargin = dp(3)
        badge.layoutParams = lp
    }

    private fun updateDot() {
        dot?.visibility = if (FloatingButton.hasDot(this)) View.VISIBLE else View.GONE
    }

    private fun wiggle() {
        val view = icon ?: return
        view.animate().cancel()
        val angles = floatArrayOf(-14f, 14f, -10f, 10f, -5f, 0f)
        var delay = 0L
        for (angle in angles) {
            handler.postDelayed({ view.animate().rotation(angle).setDuration(70).start() }, delay)
            delay += 75
        }
    }

    // Timed hide and nudges

    private fun scheduleHideTimer() {
        handler.removeCallbacks(hideTimer)
        val until = FloatingButton.hiddenUntil(this) ?: return
        val wait = (until - System.currentTimeMillis()).coerceAtLeast(1_000L)
        handler.postDelayed(hideTimer, wait)
    }

    private fun scheduleNudgeCheck() {
        handler.removeCallbacks(nudgeCheck)
        val wait = FloatingButton.millisToNextNudge(this) ?: run {
            // Nothing left today: look again just after midnight
            val cal = java.util.Calendar.getInstance()
            val minutesLeft = 24 * 60 - (cal.get(java.util.Calendar.HOUR_OF_DAY) * 60 +
                cal.get(java.util.Calendar.MINUTE))
            minutesLeft * 60_000L + 5_000L
        }
        handler.postDelayed(nudgeCheck, wait.coerceAtLeast(1_000L))
    }

    private fun checkNudges() {
        val fresh = FloatingButton.takeDueNudges(this)
        if (fresh > 0 && attached) {
            updateDot()
            if (FloatingButton.nudge(this)) wiggle()
        } else {
            updateDot()
        }
        scheduleNudgeCheck()
    }

    // Touch: tap to open, drag to move, drop on ✕ to hide

    private inner class DragListener : View.OnTouchListener {
        private val slop = ViewConfiguration.get(this@FloatingButtonService).scaledTouchSlop
        private var downRawX = 0f
        private var downRawY = 0f
        private var startX = 0
        private var startY = 0
        private var dragging = false

        @SuppressLint("ClickableViewAccessibility")
        override fun onTouch(view: View, event: MotionEvent): Boolean {
            val layout = params ?: return false
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    snapAnimator?.cancel()
                    downRawX = event.rawX
                    downRawY = event.rawY
                    startX = layout.x
                    startY = layout.y
                    dragging = false
                    root?.alpha = 1f
                    return true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downRawX
                    val dy = event.rawY - downRawY
                    if (!dragging && hypot(dx, dy) > slop) {
                        dragging = true
                        showTarget()
                    }
                    if (dragging) {
                        val size = dp(BUTTON_DP)
                        layout.x = (event.rawX - size / 2f).toInt()
                        layout.y = (event.rawY - size / 2f).toInt()
                            .coerceIn(0, (screenHeight() - size).coerceAtLeast(0))
                        updateLayout()
                        highlightTarget(overTarget(event.rawX, event.rawY))
                    }
                    return true
                }
                MotionEvent.ACTION_UP -> {
                    if (!dragging) {
                        root?.alpha = FloatingButton.opacity(this@FloatingButtonService)
                        onTap()
                        return true
                    }
                    val drop = overTarget(event.rawX, event.rawY)
                    removeTarget()
                    if (drop) {
                        FloatingButton.hideByUser(this@FloatingButtonService)
                        refresh()
                    } else {
                        snapToEdge()
                    }
                    return true
                }
                MotionEvent.ACTION_CANCEL -> {
                    removeTarget()
                    if (dragging) snapToEdge() else placeAtSavedPosition()
                    root?.alpha = FloatingButton.opacity(this@FloatingButtonService)
                    return true
                }
            }
            return false
        }
    }

    private fun onTap() {
        FloatingButton.setDot(this, false)
        updateDot()
        try {
            startActivity(QuickEntry.sheetIntent(this))
        } catch (_: Exception) {
        }
    }

    private fun snapToEdge() {
        val layout = params ?: return
        val size = dp(BUTTON_DP)
        val right = layout.x + size / 2 > screenWidth() / 2
        val usable = (screenHeight() - size).coerceAtLeast(1)
        FloatingButton.savePosition(this, right, layout.y.toFloat() / usable)
        positionDot(right)
        val from = layout.x
        val to = tuckedX(right)
        snapAnimator?.cancel()
        snapAnimator = ValueAnimator.ofInt(from, to).apply {
            duration = 220
            interpolator = DecelerateInterpolator()
            addUpdateListener {
                params?.x = it.animatedValue as Int
                updateLayout()
            }
            start()
        }
        root?.alpha = FloatingButton.opacity(this)
    }

    // The ✕ drop target at the bottom

    private fun showTarget() {
        if (targetAttached) return
        val size = dp(64)
        val frame = FrameLayout(this)
        val circle = TextView(this).apply {
            text = "✕"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 24f)
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.argb(150, 0, 0, 0))
                setStroke(dp(2), Color.WHITE)
            }
        }
        frame.addView(circle, FrameLayout.LayoutParams(size, size, Gravity.CENTER_HORIZONTAL or Gravity.TOP))
        val label = TextView(this).apply {
            text = "Drop here to hide"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setShadowLayer(6f, 0f, 1f, Color.BLACK)
            gravity = Gravity.CENTER
        }
        frame.addView(
            label,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER_HORIZONTAL or Gravity.BOTTOM
            )
        )
        val layout = WindowManager.LayoutParams(
            dp(180), dp(100), overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = dp(56)
        }
        try {
            windowManager.addView(frame, layout)
            target = frame
            targetAttached = true
        } catch (_: Exception) {
        }
    }

    private fun removeTarget() {
        if (targetAttached) {
            try {
                windowManager.removeView(target)
            } catch (_: Exception) {
            }
        }
        target = null
        targetAttached = false
    }

    /** The ✕'s centre on screen. */
    private fun targetCentre(): Pair<Float, Float> {
        val x = screenWidth() / 2f
        val y = screenHeight() - dp(56) - dp(100) + dp(32).toFloat()
        return x to y
    }

    private fun overTarget(rawX: Float, rawY: Float): Boolean {
        val (cx, cy) = targetCentre()
        return hypot(rawX - cx, rawY - cy) < dp(72)
    }

    private fun highlightTarget(on: Boolean) {
        val frame = target ?: return
        val scale = if (on) 1.15f else 1f
        val circle = frame.getChildAt(0) ?: return
        if (abs(circle.scaleX - scale) > 0.01f) {
            circle.animate().scaleX(scale).scaleY(scale).setDuration(120).start()
        }
    }
}
