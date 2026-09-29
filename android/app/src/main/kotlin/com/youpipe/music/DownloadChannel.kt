package com.youpipe.music

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import okhttp3.OkHttpClient
import okhttp3.Request
import org.schabi.newpipe.extractor.services.youtube.YoutubeParsingHelper
import java.io.File
import java.io.RandomAccessFile
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Downloads a resolved googlevideo stream to a file.
 *
 * Done natively (not with Dart's HttpClient) so requests leave through the same Android network
 * stack as extraction and playback: stream URLs are bound to the client's IP and client type, and
 * the User-Agent must match the InnerTube client that produced the URL.
 */
object DownloadChannel {
    private const val CHANNEL = "youpipe/downloader"
    private const val PROGRESS_CHANNEL = "youpipe/downloader/progress"
    private const val CHUNK = 1024L * 1024L
    private const val WEB_USER_AGENT =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0"

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val cancelled = ConcurrentHashMap.newKeySet<String>()
    private var progressSink: EventChannel.EventSink? = null

    private val client =
        OkHttpClient
            .Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()

    fun register(messenger: BinaryMessenger) {
        EventChannel(messenger, PROGRESS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?,
                ) {
                    progressSink = events
                }

                override fun onCancel(arguments: Any?) {
                    progressSink = null
                }
            },
        )

        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "download" -> {
                    val id = call.argument<String>("id")!!
                    val url = call.argument<String>("url")!!
                    val path = call.argument<String>("path")!!
                    cancelled.remove(id)
                    executor.execute {
                        try {
                            val total = download(id, url, File(path))
                            mainHandler.post { result.success(total) }
                        } catch (e: Throwable) {
                            File(path).delete()
                            val code = if (e is CancelledException) "CANCELLED" else "DOWNLOAD_FAILED"
                            mainHandler.post { result.error(code, e.message ?: e.javaClass.simpleName, null) }
                        }
                    }
                }

                "cancel" -> {
                    cancelled.add(call.argument<String>("id")!!)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private class CancelledException : Exception("cancelled")

    private fun userAgentFor(url: String): String =
        when {
            YoutubeParsingHelper.isVisionOsStreamingUrl(url) -> YoutubeParsingHelper.getVisionOsUserAgent(null)
            YoutubeParsingHelper.isAndroidStreamingUrl(url) -> YoutubeParsingHelper.getAndroidUserAgent(null)
            YoutubeParsingHelper.isIosStreamingUrl(url) -> YoutubeParsingHelper.getIosUserAgent(null)
            else -> WEB_USER_AGENT
        }

    /** Downloads in 1 MB range requests; returns the total size in bytes. */
    private fun download(
        id: String,
        url: String,
        file: File,
    ): Long {
        val userAgent = userAgentFor(url)
        file.parentFile?.mkdirs()
        var offset = 0L
        var total = -1L
        RandomAccessFile(file, "rw").use { out ->
            out.setLength(0)
            while (total < 0 || offset < total) {
                if (id in cancelled) throw CancelledException()
                val request =
                    Request
                        .Builder()
                        .url(url)
                        .header("User-Agent", userAgent)
                        .header("Range", "bytes=$offset-${offset + CHUNK - 1}")
                        .build()
                client.newCall(request).execute().use { response ->
                    if (!response.isSuccessful) throw IllegalStateException("HTTP ${response.code}")
                    if (total < 0) {
                        total = response.header("Content-Range")?.substringAfterLast('/')?.toLongOrNull()
                            ?: response.body?.contentLength()?.takeIf { it > 0 }
                            ?: throw IllegalStateException("Unknown size")
                    }
                    val bytes = response.body?.bytes() ?: ByteArray(0)
                    if (bytes.isEmpty()) throw IllegalStateException("Empty chunk at $offset")
                    out.write(bytes)
                    offset += bytes.size
                }
                val sink = progressSink
                val downloaded = offset
                val size = total
                mainHandler.post { sink?.success(mapOf("id" to id, "downloaded" to downloaded, "total" to size)) }
            }
        }
        return offset
    }
}
