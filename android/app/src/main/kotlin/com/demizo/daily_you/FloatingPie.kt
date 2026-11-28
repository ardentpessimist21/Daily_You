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
import android.graphics.drawable.Drawable
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
 *
 * 3.7.0.68: Material icons instead of emoji, and a second ring. The slice
 * under the finger shows its options just outside it (Photo and Video:
 * Front / Back, Audio: Auto record, Daily You: Search); slide on out onto
 * one and let go.
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

    enum class Slice(val label: String, val icon: Int) {
        PHOTO("Photo", R.drawable.ic_pie_photo),
        VIDEO("Video", R.drawable.ic_pie_video),
        AUDIO("Audio", R.drawable.ic_pie_mic),
        APP("Daily You", R.drawable.ic_notification),
    }

    /** The second ring's options, top to bottom within their slice. */
    enum class Option(val slice: Slice, val label: String, val icon: Int) {
        PHOTO_FRONT(Slice.PHOTO, "Front", R.drawable.ic_pie_front),
        PHOTO_BACK(Slice.PHOTO, "Back", R.drawable.ic_pie_back),
        VIDEO_FRONT(Slice.VIDEO, "Front", R.drawable.ic_pie_front),
        VIDEO_BACK(Slice.VIDEO, "Back", R.drawable.ic_pie_back),
        AUDIO_AUTO(Slice.AUDIO, "Auto record", R.drawable.ic_pie_record),
        APP_SEARCH(Slice.APP, "Search", R.drawable.ic_pie_search),
    }

    /** What letting go would pick: a slice, or one of its options. */
    data class Pick(val slice: Slice, val option: Option? = null)

    private val density = resources.displayMetrics.density
    private val radius = 132 * density
    private val hole = 44 * density
    private val outer = 206 * density

    private val dark = (resources.configuration.uiMode and
        Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    private val sliceColor = if (dark) Color.parseColor("#2B2E38") else Color.parseColor("#ECEEF3")
    private val openColor = if (dark) Color.parseColor("#323A52") else Color.parseColor("#D6DDF0")
    private val ringColor = if (dark) Color.parseColor("#353946") else Color.parseColor("#E2E5EE")
    private val litColor = Color.parseColor("#3D5BA9")
    private val textColor = if (dark) Color.parseColor("#E3E2E9") else Color.parseColor("#2B2D35")
    private val litText = Color.WHITE
    private val recordColor = Color.parseColor(if (dark) "#FF6B6B" else "#E0413A")
    private val edgeColor = if (dark) Color.parseColor("#15161B") else Color.parseColor("#B9BCC6")

    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    private val line = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = (if (dark) 2f else 1.5f) * density
        color = edgeColor
    }
    private val label = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
        textSize = 13 * density
    }

    private val icons = HashMap<Int, Drawable?>()

    private fun icon(res: Int, color: Int): Drawable? =
        icons.getOrPut(res) { ContextCompat.getDrawable(context, res)?.mutate() }?.apply {
            colorFilter = PorterDuffColorFilter(color, PorterDuff.Mode.SRC_IN)
        }

    /** The slice or option under the finger, or null. */
    var selected: Pick? = null
        private set

    /** The slice whose second ring is showing. */
    private var open: Slice? = null

    /** Top to bottom; each slice is a quarter of the half circle. */
    private val slices = Slice.values()

    /** Angle (degrees, 0 = right, clockwise) where slice [index] starts. */
    private fun startAngle(index: Int): Float =
        if (opensLeft) 270f - 45f * (index + 1) else -90f + 45f * index

    private fun optionsOf(slice: Slice) = Option.values().filter { it.slice == slice }

    /** Where option [index] of [count] starts in the slice starting at [start]. */
    private fun optionStart(start: Float, index: Int, count: Int): Float {
        val step = 45f / count
        // Top to bottom: opening left the top is the slice's far end
        return if (opensLeft) start + 45f - step * (index + 1) else start + step * index
    }

    private fun inSpan(angle: Float, start: Float, sweep: Float): Boolean {
        var offset = (angle - start) % 360f
        if (offset < 0) offset += 360f
        return offset < sweep
    }

    fun pointAt(rawX: Float, rawY: Float) {
        val dx = rawX - centerX
        val dy = rawY - centerY
        val distance = hypot(dx, dy)
        val angle = Math.toDegrees(atan2(dy.toDouble(), dx.toDouble())).toFloat()
        var found: Pick? = null
        var showing = open
        if (distance > hole * 0.7f) {
            val index = slices.indices.firstOrNull { inSpan(angle, startAngle(it), 45f) }
            if (index != null) {
                val slice = slices[index]
                if (distance <= radius) {
                    found = Pick(slice)
                    showing = slice
                } else if (distance < outer * 1.5f) {
                    // Out past the slices: the option under the finger, on
                    // whichever slice's ring that is
                    val options = optionsOf(slice)
                    val start = startAngle(index)
                    val option = options.indices.firstOrNull {
                        inSpan(angle, optionStart(start, it, options.size), 45f / options.size)
                    }?.let { options[it] }
                    if (option != null) {
                        found = Pick(slice, option)
                        showing = slice
                    }
                }
            }
        } else {
            showing = null
        }
        if (found != selected || showing != open) {
            if (found != selected && found != null) {
                performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
            }
            selected = found
            open = showing
            invalidate()
        }
    }

    private fun ringSlice(box: RectF, inner: RectF, start: Float, sweep: Float) = Path().apply {
        arcTo(box, start, sweep, true)
        arcTo(inner, start + sweep, -sweep)
        close()
    }

    private fun drawLabel(
        canvas: Canvas, text: String, iconRes: Int, angle: Float, distance: Float,
        lit: Boolean, iconColor: Int? = null,
    ) {
        val middle = Math.toRadians(angle.toDouble())
        val x = centerX + distance * cos(middle).toFloat()
        val y = centerY + distance * sin(middle).toFloat()
        val color = if (lit) litText else textColor
        label.color = color
        label.typeface = if (lit) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        canvas.drawText(text, x, y + 16 * density, label)
        icon(iconRes, if (lit) litText else iconColor ?: color)?.let {
            val half = (11 * density).toInt()
            val top = (y - 18 * density).toInt()
            it.setBounds(x.toInt() - half, top, x.toInt() + half, top + half * 2)
            it.draw(canvas)
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
        val far = RectF(centerX - outer, centerY - outer, centerX + outer, centerY + outer)
        val pick = selected
        for ((index, slice) in slices.withIndex()) {
            val start = startAngle(index)
            val lit = pick != null && pick.slice == slice && pick.option == null
            fill.color = when {
                lit -> litColor
                open == slice -> openColor
                else -> sliceColor
            }
            // A ring slice, so the button shows through the middle
            val path = ringSlice(box, inner, start, 45f)
            canvas.drawPath(path, fill)
            canvas.drawPath(path, line)
            drawLabel(canvas, slice.label, slice.icon, start + 22.5f, radius * 0.66f, lit)

            // The second ring, just outside the slice that's open
            if (open != slice) continue
            val options = optionsOf(slice)
            val step = 45f / options.size
            for ((optionIndex, option) in options.withIndex()) {
                val optionStart = optionStart(start, optionIndex, options.size)
                val optionLit = pick?.option == option
                fill.color = if (optionLit) litColor else ringColor
                val optionPath = ringSlice(far, box, optionStart, step)
                canvas.drawPath(optionPath, fill)
                canvas.drawPath(optionPath, line)
                drawLabel(
                    canvas, option.label, option.icon, optionStart + step / 2,
                    (radius + outer) / 2f - 4 * density, optionLit,
                    if (option == Option.AUDIO_AUTO) recordColor else null,
                )
            }
        }
    }
}
