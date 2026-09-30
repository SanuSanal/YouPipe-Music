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
import org.schabi.newpipe.extractor.stream.AudioStream
import org.schabi.newpipe.extractor.stream.AudioTrackType
import org.schabi.newpipe.extractor.stream.DeliveryMethod
import org.schabi.newpipe.extractor.stream.Stream
import org.schabi.newpipe.extractor.stream.VideoStream
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

                "getVideoManifest" -> {
                    val videoId = call.argument<String>("videoId")
                    if (videoId.isNullOrBlank()) {
                        result.error("BAD_ARGS", "videoId is required", null)
                        return@setMethodCallHandler
                    }
                    val hl = call.argument<String>("hl") ?: "en"
                    val gl = call.argument<String>("gl") ?: "US"
                    val maxHeight = call.argument<Int>("maxHeight") ?: 1080
                    val onlyBest = call.argument<Boolean>("onlyBest") ?: false
                    run(result) { getVideoManifest(videoId, hl, gl, maxHeight, onlyBest) }
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
                        is NoHdException -> "NO_HD"
                        else -> "EXTRACTION_FAILED"
                    }
                mainHandler.post { result.error(code, e.message ?: e.javaClass.simpleName, null) }
            }
        }
    }

    private class NoVideoException(
        videoId: String,
    ) : Exception("No playable video stream for $videoId")

    private class NoHdException(
        videoId: String,
    ) : Exception("No video-only streams to build a manifest for $videoId")

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
            originalAudio(extractor.audioStreams)
                .map { s ->
                    mapOf(
                        "url" to s.content,
                        "itag" to s.itag,
                        "mimeType" to s.format?.mimeType,
                        "codec" to s.codec,
                        // kbps: averageBitrate already is, bitrate is in bits per second.
                        "bitrate" to (s.averageBitrate.takeIf { it > 0 } ?: (s.bitrate / 1000)),
                        "contentLength" to (s.itagItem?.contentLength ?: -1L),
                    )
                }

        return mapOf(
            "videoId" to videoId,
            "durationSeconds" to extractor.length,
            "streams" to streams,
        )
    }

    /**
     * Progressive audio on the original track. DRC ("stable volume") copies have their dynamic range
     * compressed, so they're only kept when nothing else is offered.
     */
    private fun originalAudio(all: List<AudioStream>): List<AudioStream> {
        val original =
            all
                .filter { it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP && it.isUrl }
                // Dubbed/descriptive tracks exist on some videos; keep the original when available.
                .filter { it.audioTrackType == null || it.audioTrackType == AudioTrackType.ORIGINAL }
        return original.filter { it.itagItem?.isDrc() != true }.ifEmpty { original }
    }

    /**
     * HD video mode (docs/streaming.md): a static DASH manifest joining the video-only streams (up to
     * [maxHeight], H.264 preferred) with the best audio stream. ExoPlayer plays it through
     * `video_player` and switches between the heights by bandwidth; [onlyBest] keeps just the tallest.
     */
    private fun getVideoManifest(
        videoId: String,
        hl: String,
        gl: String,
        maxHeight: Int,
        onlyBest: Boolean,
    ): Map<String, Any?> {
        ensureInit(hl, gl)
        val extractor = ServiceList.YouTube.getStreamExtractor("https://www.youtube.com/watch?v=$videoId")
        extractor.fetchPage()
        val durationSeconds = extractor.length
        val usable =
            extractor.videoOnlyStreams
                .filter { it.deliveryMethod == DeliveryMethod.PROGRESSIVE_HTTP && it.isUrl && it.hasRanges() }
                // ExoPlayer starts low and steps up; below 360p it only looks blurry.
                .filter { it.height in 360..maxHeight }
        val avc = usable.filter { it.codec.orEmpty().startsWith("avc1") }
        val vp9 = usable.filter { it.codec.orEmpty().let { c -> c.startsWith("vp9") || c.startsWith("vp09") } }
        var video =
            avc
                .ifEmpty { vp9 }
                .groupBy { it.height }
                .map { (_, same) -> same.maxBy { it.bitrate } }
                .sortedBy { it.height }
        if (onlyBest) video = video.takeLast(1)
        // Below 480p a manifest is no better than the muxed 360p stream.
        if (video.isEmpty() || video.last().height < 480 || durationSeconds <= 0) throw NoHdException(videoId)
        val audio =
            originalAudio(extractor.audioStreams)
                .filter { it.hasRanges() }
                .let { list -> list.filter { it.codec.orEmpty().contains("opus") }.ifEmpty { list } }
                .maxByOrNull { it.bitrate }
                ?: throw NoHdException(videoId)
        return mapOf(
            "videoId" to videoId,
            "mpd" to buildMpd(video, audio, durationSeconds),
            "height" to video.last().height,
            "userAgent" to Googlevideo.userAgentFor(video.last().content),
            "durationSeconds" to durationSeconds,
        )
    }

    private fun Stream.hasRanges(): Boolean {
        val i = itagItem ?: return false
        return i.initEnd > 0 && i.indexStart > 0 && i.indexEnd > i.indexStart
    }

    private fun xml(s: String) =
        s
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")

    /** One Representation's media: the stream URL plus its init and sidx byte ranges. */
    private fun segmentBase(s: Stream): String {
        val i = s.itagItem!!
        return "<BaseURL>${xml(s.content)}</BaseURL>" +
            "<SegmentBase indexRange=\"${i.indexStart}-${i.indexEnd}\">" +
            "<Initialization range=\"${i.initStart}-${i.initEnd}\"/></SegmentBase>"
    }

    private fun buildMpd(
        video: List<VideoStream>,
        audio: AudioStream,
        durationSeconds: Long,
    ): String =
        buildString {
            append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
            append("<MPD xmlns=\"urn:mpeg:dash:schema:mpd:2011\" profiles=\"urn:mpeg:dash:profile:isoff-on-demand:2011\"")
            append(" type=\"static\" minBufferTime=\"PT1.5S\" mediaPresentationDuration=\"PT${durationSeconds}S\">")
            append("<Period>")
            val videoMime = video.first().format?.mimeType ?: "video/mp4"
            append("<AdaptationSet id=\"0\" contentType=\"video\" mimeType=\"$videoMime\">")
            video.forEachIndexed { n, v ->
                append("<Representation id=\"v$n\" codecs=\"${xml(v.codec.orEmpty())}\" bandwidth=\"${v.bitrate}\"")
                append(" width=\"${v.width}\" height=\"${v.height}\"")
                if (v.fps > 0) append(" frameRate=\"${v.fps}\"")
                append(">${segmentBase(v)}</Representation>")
            }
            append("</AdaptationSet>")
            val audioMime = audio.format?.mimeType ?: "audio/mp4"
            append("<AdaptationSet id=\"1\" contentType=\"audio\" mimeType=\"$audioMime\">")
            append("<Representation id=\"a0\" codecs=\"${xml(audio.codec.orEmpty())}\" bandwidth=\"${audio.bitrate}\"")
            audio.itagItem?.sampleRate?.takeIf { it > 0 }?.let { append(" audioSamplingRate=\"$it\"") }
            append(">${segmentBase(audio)}</Representation>")
            append("</AdaptationSet></Period></MPD>")
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
