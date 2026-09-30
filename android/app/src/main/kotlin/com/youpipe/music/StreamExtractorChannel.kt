package com.youpipe.music

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import okhttp3.OkHttpClient
import okhttp3.RequestBody.Companion.toRequestBody
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.exceptions.AgeRestrictedContentException
import org.schabi.newpipe.extractor.exceptions.ContentNotAvailableException
import org.schabi.newpipe.extractor.exceptions.GeographicRestrictionException
import org.schabi.newpipe.extractor.exceptions.ReCaptchaException
import org.schabi.newpipe.extractor.localization.ContentCountry
import org.schabi.newpipe.extractor.localization.Localization
import org.schabi.newpipe.extractor.stream.AudioTrackType
import org.schabi.newpipe.extractor.stream.DeliveryMethod
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Resolves a YouTube videoId into directly playable audio stream URLs using NewPipeExtractor.
 *
 * This is the only part of YouPipe that does not go through the Dart InnerTube client: stream URLs
 * need signature/n-param deciphering and YouTube's client/PO-token workarounds, which
 * NewPipeExtractor maintains.
 */
object StreamExtractorChannel {
    private const val CHANNEL = "youpipe/stream_extractor"

    private val executor = Executors.newFixedThreadPool(3)
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var initialized = false

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAudioStreams" -> {
                    val videoId = call.argument<String>("videoId")
                    if (videoId.isNullOrBlank()) {
                        result.error("BAD_ARGS", "videoId is required", null)
                        return@setMethodCallHandler
                    }
                    val hl = call.argument<String>("hl") ?: "en"
                    val gl = call.argument<String>("gl") ?: "US"
                    run(result) { getAudioStreams(videoId, hl, gl) }
                }

                "getVideoStream" -> {
                    val videoId = call.argument<String>("videoId")
                    if (videoId.isNullOrBlank()) {
                        result.error("BAD_ARGS", "videoId is required", null)
                        return@setMethodCallHandler
                    }
                    val hl = call.argument<String>("hl") ?: "en"
                    val gl = call.argument<String>("gl") ?: "US"
                    run(result) { getVideoStream(videoId, hl, gl) }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun run(
        result: MethodChannel.Result,
        work: () -> Any?,
    ) {
        executor.execute {
            try {
                val data = work()
                mainHandler.post { result.success(data) }
            } catch (e: Throwable) {
                val code =
                    when (e) {
                        is AgeRestrictedContentException -> "AGE_RESTRICTED"
                        is GeographicRestrictionException -> "GEO_RESTRICTED"
                        is ContentNotAvailableException -> "UNAVAILABLE"
                        is ReCaptchaException -> "RECAPTCHA"
                        is NoVideoException -> "NO_VIDEO"
                        else -> "EXTRACTION_FAILED"
                    }
                mainHandler.post { result.error(code, e.message ?: e.javaClass.simpleName, null) }
            }
        }
    }

    private class NoVideoException(
        videoId: String,
    ) : Exception("No playable video stream for $videoId")

    /**
     * Video mode (docs/playback.md): the best progressive stream with both video and audio, at most
     * 720p (in practice YouTube only muxes 360p). The User-Agent to play it with comes along, since
     * the URL is bound to the InnerTube client that produced it.
     */
    private fun getVideoStream(
        videoId: String,
        hl: String,
        gl: String,
    ): Map<String, Any?> {
        ensureInit(hl, gl)
        val extractor = ServiceList.YouTube.getStreamExtractor("https://www.youtube.com/watch?v=$videoId")
        extractor.fetchPage()
        val best =
            extractor.videoStreams
                .filter { it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP && it.isUrl && !it.isVideoOnly }
                .filter { it.height in 1..720 }
                .maxByOrNull { it.height } ?: throw NoVideoException(videoId)
        return mapOf(
            "videoId" to videoId,
            "url" to best.content,
            "height" to best.height,
            "mimeType" to best.format?.mimeType,
            "userAgent" to Googlevideo.userAgentFor(best.content),
            "durationSeconds" to extractor.length,
        )
    }

    fun ensureInit(
        hl: String,
        gl: String,
    ) {
        if (!initialized) {
            synchronized(this) {
                if (!initialized) {
                    NewPipe.init(OkHttpDownloader, Localization(hl, gl), ContentCountry(gl))
                    initialized = true
                }
            }
        }
    }

    /** Also used by [CastProxy], which picks its own format. */
    fun getAudioStreams(
        videoId: String,
        hl: String,
        gl: String,
    ): Map<String, Any?> {
        ensureInit(hl, gl)
        val extractor = ServiceList.YouTube.getStreamExtractor("https://www.youtube.com/watch?v=$videoId")
        extractor.fetchPage()

        val streams =
            extractor.audioStreams
                .filter { it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP && it.isUrl }
                // Dubbed/descriptive tracks exist on some videos; keep the original when available.
                .filter { it.audioTrackType == null || it.audioTrackType == AudioTrackType.ORIGINAL }
                .map { s ->
                    mapOf(
                        "url" to s.content,
                        "itag" to s.itag,
                        "mimeType" to s.format?.mimeType,
                        "codec" to s.codec,
                        "bitrate" to (s.averageBitrate.takeIf { it > 0 } ?: s.bitrate),
                        "contentLength" to (s.itagItem?.contentLength ?: -1L),
                    )
                }

        return mapOf(
            "videoId" to videoId,
            "durationSeconds" to extractor.length,
            "streams" to streams,
        )
    }

    private object OkHttpDownloader : Downloader() {
        private const val USER_AGENT =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0"

        private val client =
            OkHttpClient
                .Builder()
                .readTimeout(30, TimeUnit.SECONDS)
                .build()

        override fun execute(request: Request): Response {
            val body = request.dataToSend()?.toRequestBody()
            val builder =
                okhttp3.Request
                    .Builder()
                    .method(request.httpMethod(), body)
                    .url(request.url())
                    .addHeader("User-Agent", USER_AGENT)

            request.headers().forEach { (name, values) ->
                builder.removeHeader(name)
                values.forEach { builder.addHeader(name, it) }
            }

            client.newCall(builder.build()).execute().use { response ->
                if (response.code == 429) {
                    throw ReCaptchaException("reCaptcha challenge requested", request.url())
                }
                return Response(
                    response.code,
                    response.message,
                    response.headers.toMultimap(),
                    response.body?.string(),
                    response.request.url.toString(),
                )
            }
        }
    }
}
