package com.youpipe.music

import android.animation.ValueAnimator
import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.drawable.Drawable
import android.view.animation.LinearInterpolator
import kotlin.math.PI
import kotlin.math.min
import kotlin.math.sin

/**
 * The lock screen player's seek bar track: the played part is a small sine wave that drifts while
 * music plays and flattens out when paused; the rest is a faint straight line.
 *
 * ProgressBar drives it through the drawable level (0..10000).
 */
class WavyProgressDrawable(
    density: Float,
) : Drawable() {
    private val amplitude = 3f * density
    private val wavelength = 22f * density
    private val stroke = 2.5f * density

    private val played =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = stroke
            strokeCap = Paint.Cap.ROUND
            color = 0xFFFFFFFF.toInt()
        }
    private val remaining =
        Paint(played).apply { color = 0x4DFFFFFF }
    private val path = Path()

    /** 0 = flat line, 1 = full wave. */
    private var height = 0f
    private var phase = 0f

    private val drift =
        ValueAnimator.ofFloat(0f, (2 * PI).toFloat()).apply {
            duration = 1600
            repeatCount = ValueAnimator.INFINITE
            interpolator = LinearInterpolator()
            addUpdateListener {
                phase = it.animatedValue as Float
                invalidateSelf()
            }
        }
    private var heightAnimator: ValueAnimator? = null

    var playing = false
        set(value) {
            if (field == value) return
            field = value
            if (value) drift.start()
            heightAnimator?.cancel()
            heightAnimator =
                ValueAnimator.ofFloat(height, if (value) 1f else 0f).apply {
                    duration = 400
                    addUpdateListener {
                        height = it.animatedValue as Float
                        invalidateSelf()
                    }
                    doOnEnd { if (!playing) drift.cancel() }
                    start()
                }
        }

    override fun draw(canvas: Canvas) {
        val b = bounds
        val cy = b.exactCenterY()
        val end = b.left + b.width() * (level / 10000f)

        path.reset()
        path.moveTo(b.left.toFloat(), cy)
        var x = b.left.toFloat()
        while (x < end) {
            x = min(x + 2f, end)
            // Taper the wave into the thumb so the line meets it at the centre.
            val taper = min(1f, (end - x) / wavelength)
            val y = cy + amplitude * height * taper * sin(2 * PI * (x - b.left) / wavelength - phase).toFloat()
            path.lineTo(x, y)
        }
        canvas.drawPath(path, played)
        if (end < b.right) canvas.drawLine(end + stroke, cy, b.right.toFloat(), cy, remaining)
    }

    override fun onLevelChange(level: Int): Boolean {
        invalidateSelf()
        return true
    }

    override fun getIntrinsicHeight() = (2 * amplitude + 2 * stroke).toInt()

    override fun setAlpha(alpha: Int) {
        played.alpha = alpha
        remaining.alpha = alpha * 0x4D / 0xFF
    }

    override fun setColorFilter(colorFilter: ColorFilter?) {
        played.colorFilter = colorFilter
        remaining.colorFilter = colorFilter
    }

    @Deprecated("Deprecated in Java")
    override fun getOpacity() = PixelFormat.TRANSLUCENT

    private fun ValueAnimator.doOnEnd(block: () -> Unit) {
        addListener(
            object : android.animation.AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: android.animation.Animator) = block()
            },
        )
    }
}
