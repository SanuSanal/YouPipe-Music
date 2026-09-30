package com.youpipe.music

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.RandomAccessFile
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

/**
 * Downloads a resolved googlevideo stream to a file.
 *
 * Done natively (not with Dart's HttpClient) so requests leave through the same Android network
 * stack as extraction and playback: stream URLs are bound to the client's IP and client type, and
 * the User-Agent must match the InnerTube client that produced the URL (see [Googlevideo]).
 */
object DownloadChannel {
    private const val CHANNEL = "youpipe/downloader"
    private const val PROGRESS_CHANNEL = "youpipe/downloader/progress"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val cancelled = ConcurrentHashMap.newKeySet<String>()
    private var progressSink: EventChannel.EventSink? = null

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

    /** Downloads in 1 MB range requests; returns the total size in bytes. */
    private fun download(
        id: String,
        url: String,
        file: File,
    ): Long {
        file.parentFile?.mkdirs()
        var offset = 0L
        var total = -1L
        RandomAccessFile(file, "rw").use { out ->
            out.setLength(0)
            while (total < 0 || offset < total) {
                if (id in cancelled) throw CancelledException()
                Googlevideo.range(url, offset, offset + Googlevideo.CHUNK - 1).use { response ->
                    if (!response.isSuccessful) throw IllegalStateException("HTTP ${response.code}")
                    if (total < 0) total = Googlevideo.totalSize(response) ?: throw IllegalStateException("Unknown size")
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
