package com.youpipe.music

import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

/**
 * The equalizer and loudness boost, attached to just_audio's audio session.
 *
 * Best-effort: when the system refuses an effect, it's reported as unavailable and the song still
 * plays. just_audio's own AudioPipeline left its native player half-built in that case, and every
 * load then failed (docs/playback.md). The wanted settings are kept here and applied on attach.
 */
object AudioEffectsChannel {
    private const val TAG = "YouPipeEffects"

    private var eqEnabled = false
    private var gains = DoubleArray(0)
    private var loudnessDb = 0.0

    private var equalizer: Equalizer? = null
    private var loudness: LoudnessEnhancer? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "youpipe/effects").setMethodCallHandler { call, result ->
            when (call.method) {
                "attach" -> result.success(attach(call.argument<Int>("session")))
                "setEqEnabled" -> {
                    eqEnabled = call.argument<Boolean>("enabled") ?: false
                    applyEqualizer()
                    result.success(null)
                }

                "setGains" -> {
                    gains = (call.argument<List<Double>>("gains") ?: emptyList()).toDoubleArray()
                    applyEqualizer()
                    result.success(null)
                }

                "setLoudness" -> {
                    loudnessDb = call.argument<Double>("db") ?: 0.0
                    applyLoudness()
                    result.success(null)
                }

                "release" -> {
                    release()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun attach(session: Int?): Map<String, Any?> {
        release()
        if (session == null || session <= 0) return mapOf("session" to false)
        var eqError: String? = null
        var loudnessError: String? = null
        try {
            equalizer = Equalizer(0, session)
            applyEqualizer()
        } catch (e: Throwable) {
            equalizer = null
            eqError = e.toString()
            Log.w(TAG, "Equalizer unavailable", e)
        }
        try {
            loudness = LoudnessEnhancer(session)
            applyLoudness()
        } catch (e: Throwable) {
            loudness = null
            loudnessError = e.toString()
            Log.w(TAG, "LoudnessEnhancer unavailable", e)
        }
        return mapOf(
            "session" to true,
            "eq" to equalizer?.let(::describe),
            "eqError" to eqError,
            "loudness" to (loudness != null),
            "loudnessError" to loudnessError,
        )
    }

    private fun describe(eq: Equalizer): Map<String, Any>? = try {
        val range = eq.bandLevelRange
        mapOf(
            "minDb" to range[0] / 100.0,
            "maxDb" to range[1] / 100.0,
            // getCenterFreq is in milliHertz.
            "bands" to (0 until eq.numberOfBands).map { eq.getCenterFreq(it.toShort()) / 1000.0 },
        )
    } catch (e: Throwable) {
        Log.w(TAG, "Equalizer parameters unavailable", e)
        null
    }

    private fun applyEqualizer() {
        val eq = equalizer ?: return
        try {
            val range = eq.bandLevelRange
            for (i in 0 until minOf(eq.numberOfBands.toInt(), gains.size)) {
                val mB = (gains[i] * 100).roundToInt().coerceIn(range[0].toInt(), range[1].toInt())
                eq.setBandLevel(i.toShort(), mB.toShort())
            }
            eq.enabled = eqEnabled
        } catch (e: Throwable) {
            Log.w(TAG, "Couldn't apply the equalizer", e)
        }
    }

    private fun applyLoudness() {
        val fx = loudness ?: return
        try {
            fx.setTargetGain((loudnessDb * 100).roundToInt())
            fx.enabled = loudnessDb > 0
        } catch (e: Throwable) {
            Log.w(TAG, "Couldn't apply the loudness boost", e)
        }
    }

    private fun release() {
        try {
            equalizer?.release()
        } catch (_: Throwable) {
        }
        try {
            loudness?.release()
        } catch (_: Throwable) {
        }
        equalizer = null
        loudness = null
    }
}
