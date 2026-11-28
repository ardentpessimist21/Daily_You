// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

package com.demizo.daily_you

import android.annotation.SuppressLint
import android.content.Context
import android.content.res.Configuration
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.RectF
import android.graphics.Typeface
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.core.content.ContextCompat
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.sin

/**
 * The floating button's pie (Update 68): hold the button still and a half
 * pie opens away from the screen edge with Photo, Video, Audio and Daily
 * You. Keep holding, slide onto a slice and let go; letting go anywhere
 * else closes it. It never takes touches itself: the button's own gesture
 * drives it through [pointAt].
 */
@SuppressLint("ViewConstructor")
class FloatingPie(
    context: Context,
    /** The button's centre on screen. */
    private val centerX: Float,
    private val centerY: Float,
    /** True when the button sits on the right: the pie opens to the left. */
    private val opensLeft: Boolean,
) : View(context) {

    enum class Slice(val label: String) {
        PHOTO("Photo"), VIDEO("Video"), AUDIO("Audio"), APP("Daily You")
    }

    private val density = resources.displayMetrics.density
    private val radius = 132 * density
    private val hole = 44 * density

    private val dark = (resources.configuration.uiMode and
        Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    private val sliceColor = if (dark) Color.parseColor("#2A2D36") else Color.parseColor("#ECEEF6")
    private val litColor = if (dark) Color.parseColor("#3B5A9A") else Color.parseColor("#C5D5FA")
    private val textColor = if (dark) Color.parseColor("#E3E2E9") else Color.parseColor("#1B1C22")
    private val holeColor = if (dark) Color.parseColor("#121318") else Color.WHITE

    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    private val line = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 3 * density
        color = holeColor
    }
    private val label = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
        textSize = 13 * density
        color = textColor
    }
    private val emoji = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
        textSize = 21 * density
    }

    /** The app's logo: white in dark mode, dark in light mode. */
    private val logo = ContextCompat.getDrawable(context, R.drawable.ic_notification)?.mutate()?.apply {
        colorFilter = PorterDuffColorFilter(
            if (dark) Color.WHITE else Color.parseColor("#1B1C22"), PorterDuff.Mode.SRC_IN
        )
    }

    /** The slice under the finger, or null. */
    var selected: Slice? = null
        private set

    /** Top to bottom; each slice is a quarter of the half circle. */
    private val slices = Slice.values()

    /** Angle (degrees, 0 = right, clockwise) where slice [index] starts. */
    private fun startAngle(index: Int): Float =
        if (opensLeft) 270f - 45f * (index + 1) else -90f + 45f * index

    fun pointAt(rawX: Float, rawY: Float) {
        val dx = rawX - centerX
        val dy = rawY - centerY
        val distance = hypot(dx, dy)
        var found: Slice? = null
        if (distance > hole * 0.7f && distance < radius * 1.8f) {
            var angle = Math.toDegrees(atan2(dy.toDouble(), dx.toDouble())).toFloat()
            for ((index, slice) in slices.withIndex()) {
                val start = startAngle(index)
                var offset = (angle - start) % 360f
                if (offset < 0) offset += 360f
                if (offset < 45f) {
                    found = slice
                    break
                }
            }
        }
        if (found != selected) {
            selected = found
            if (found != null) performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
            invalidate()
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        // Dim everything but the button itself
        val dim = Path().apply {
            fillType = Path.FillType.EVEN_ODD
            addRect(0f, 0f, width.toFloat(), height.toFloat(), Path.Direction.CW)
            addCircle(centerX, centerY, hole * 0.62f, Path.Direction.CW)
        }
        fill.color = Color.argb(if (dark) 110 else 70, 0, 0, 0)
        canvas.drawPath(dim, fill)
        val box = RectF(centerX - radius, centerY - radius, centerX + radius, centerY + radius)
        val inner = RectF(centerX - hole, centerY - hole, centerX + hole, centerY + hole)
        for ((index, slice) in slices.withIndex()) {
            val start = startAngle(index)
            fill.color = if (slice == selected) litColor else sliceColor
            // A ring slice, so the button shows through the middle
            val path = Path().apply {
                arcTo(box, start, 45f, true)
                arcTo(inner, start + 45f, -45f)
                close()
            }
            canvas.drawPath(path, fill)
            canvas.drawPath(path, line)

            val middle = Math.toRadians((start + 22.5f).toDouble())
            val x = centerX + (radius * 0.66f) * cos(middle).toFloat()
            val y = centerY + (radius * 0.66f) * sin(middle).toFloat()
            label.typeface = if (slice == selected) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
            canvas.drawText(slice.label, x, y + 16 * density, label)
            when (slice) {
                Slice.PHOTO -> canvas.drawText("📷", x, y, emoji)
                Slice.VIDEO -> canvas.drawText("🎥", x, y, emoji)
                Slice.AUDIO -> canvas.drawText("🎙", x, y, emoji)
                Slice.APP -> logo?.let {
                    val half = (11 * density).toInt()
                    val top = (y - 18 * density).toInt()
                    it.setBounds(x.toInt() - half, top, x.toInt() + half, top + half * 2)
                    it.draw(canvas)
                }
            }
        }
    }
}
