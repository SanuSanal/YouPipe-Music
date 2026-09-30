package com.youpipe.music

import android.util.Log
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.io.InputStream
import java.io.OutputStream
import java.io.RandomAccessFile
import java.net.Inet4Address
import java.net.NetworkInterface
import java.net.ServerSocket
import java.net.Socket
import java.util.UUID
import java.util.concurrent.Executors

/**
 * A tiny HTTP server on the local network that serves the current song to a Chromecast or DLNA
 * renderer (docs/cast.md).
 *
 * The receiver can't fetch googlevideo URLs itself: they're bound to this phone's IP and InnerTube
 * client. So it asks this proxy (`http://<phone>:<port>/a/<token>`), which fetches the audio from
 * this phone in 1 MB ranges with the right User-Agent, or reads a downloaded file. Only tokens
 * handed out by [register] are served, and the server only runs while a Cast session is live.
 */
object CastProxy {
    private const val TAG = "YouPipeCastProxy"
    private const val KEEP_TOKENS = 4

    /** Byte seeking allowed, streaming transfer (DLNA.ORG_OP=01, FLAGS). Also used in the DIDL metadata. */
    const val DLNA_FEATURES = "DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000"

    private sealed interface Source {
        data class Remote(
            val videoId: String,
        ) : Source

        data class Local(
            val file: File,
        ) : Source
    }

    /** A resolved googlevideo stream for one token. */
    private class Stream(
        val url: String,
        val mime: String,
        val size: Long,
    )

    private val pool = Executors.newCachedThreadPool()
    private val sources = LinkedHashMap<String, Source>()
    private val streams = HashMap<String, Stream>()
    private var server: ServerSocket? = null

    @Synchronized
    fun start() {
        if (server != null) return
        val socket = ServerSocket(0)
        server = socket
        pool.execute { accept(socket) }
    }

    @Synchronized
    fun stop() {
        runCatching { server?.close() }
        server = null
        sources.clear()
        streams.clear()
    }

    /** What a receiver should load: the proxy URL and the audio's content type. */
    class Registered(
        val url: String,
        val contentType: String,
    )

    /**
     * Makes a song available to receivers on the LAN. For a streamed song this resolves the stream
     * (network work: call it off the main thread). Null when the phone has no LAN address.
     */
    fun register(
        videoId: String,
        localPath: String?,
    ): Registered? {
        val host = lanAddress() ?: return null
        val token = UUID.randomUUID().toString().replace("-", "")
        val port: Int
        synchronized(this) {
            start()
            port = server!!.localPort
            sources[token] = if (localPath != null) Source.Local(File(localPath)) else Source.Remote(videoId)
            while (sources.size > KEEP_TOKENS) {
                val oldest = sources.keys.first()
                sources.remove(oldest)
                streams.remove(oldest)
            }
        }
        val mime = if (localPath != null) mimeOf(File(localPath)) else streamFor(token, videoId, refresh = false).mime
        return Registered("http://$host:$port/a/$token", mime)
    }

    private fun accept(socket: ServerSocket) {
        while (!socket.isClosed) {
            val client = runCatching { socket.accept() }.getOrNull() ?: break
            pool.execute { runCatching { serve(client) }.onFailure { Log.d(TAG, "request ended: $it") } }
        }
    }

    private fun serve(client: Socket) =
        client.use { socket ->
            socket.soTimeout = 30_000
            val input = BufferedInputStream(socket.getInputStream())
            val out = BufferedOutputStream(socket.getOutputStream(), 64 * 1024)
            val requestLine = readLine(input) ?: return
            val headers = HashMap<String, String>()
            while (true) {
                val line = readLine(input) ?: break
                if (line.isEmpty()) break
                val colon = line.indexOf(':')
                if (colon > 0) headers[line.substring(0, colon).trim().lowercase()] = line.substring(colon + 1).trim()
            }
            val (method, path) = requestLine.split(' ').let { it.getOrNull(0) to it.getOrNull(1) }
            val token = path?.takeIf { it.startsWith("/a/") }?.removePrefix("/a/")?.substringBefore('?')
            val source = synchronized(this) { token?.let { sources[it] } }
            if (source == null || (method != "GET" && method != "HEAD")) {
                writeHead(out, 404, "Not Found", emptyMap())
                out.flush()
                return
            }
            val head = method == "HEAD"
            when (source) {
                is Source.Local -> serveFile(source.file, headers["range"], head, out)
                is Source.Remote -> serveRemote(token!!, source.videoId, headers["range"], head, out)
            }
            out.flush()
        }

    private fun serveFile(
        file: File,
        rangeHeader: String?,
        head: Boolean,
        out: OutputStream,
    ) {
        val size = file.length()
        val (start, end) = parseRange(rangeHeader, size)
        writeRangeHead(out, rangeHeader != null, start, end, size, mimeOf(file))
        if (head) return
        RandomAccessFile(file, "r").use { raf ->
            raf.seek(start)
            val buffer = ByteArray(64 * 1024)
            var left = end - start + 1
            while (left > 0) {
                val n = raf.read(buffer, 0, minOf(buffer.size.toLong(), left).toInt())
                if (n < 0) break
                out.write(buffer, 0, n)
                left -= n
            }
        }
    }

    private fun serveRemote(
        token: String,
        videoId: String,
        rangeHeader: String?,
        head: Boolean,
        out: OutputStream,
    ) {
        var stream = streamFor(token, videoId, refresh = false)
        val (start, end) = parseRange(rangeHeader, stream.size)
        writeRangeHead(out, rangeHeader != null, start, end, stream.size, stream.mime)
        if (head) return
        var offset = start
        var retried = false
        while (offset <= end) {
            val chunkEnd = minOf(end, offset + Googlevideo.CHUNK - 1)
            Googlevideo.range(stream.url, offset, chunkEnd).use { response ->
                if (response.code == 403 && !retried) {
                    // The URL expired or was rejected: extract a fresh one once and carry on.
                    retried = true
                    stream = streamFor(token, videoId, refresh = true)
                    return@use
                }
                if (!response.isSuccessful) throw IllegalStateException("HTTP ${response.code}")
                val body = response.body?.byteStream() ?: throw IllegalStateException("Empty body")
                offset += copy(body, out)
            }
        }
    }

    /** Picks AAC/MP4 when there is one (every receiver plays it), else the best other stream. */
    private fun streamFor(
        token: String,
        videoId: String,
        refresh: Boolean,
    ): Stream {
        if (!refresh) synchronized(this) { streams[token] }?.let { return it }
        @Suppress("UNCHECKED_CAST")
        val all = StreamExtractorChannel.getAudioStreams(videoId, "en", "US")["streams"] as List<Map<String, Any?>>
        val best =
            all
                .sortedWith(
                    compareByDescending<Map<String, Any?>> { (it["mimeType"] as? String) == "audio/mp4" }
                        .thenByDescending { (it["bitrate"] as? Number)?.toInt() ?: 0 },
                ).firstOrNull() ?: throw IllegalStateException("No streams for $videoId")
        val url = best["url"] as String
        val size =
            (best["contentLength"] as? Number)?.toLong()?.takeIf { it > 0 }
                ?: Googlevideo.range(url, 0, 0).use { Googlevideo.totalSize(it) }
                ?: throw IllegalStateException("Unknown size")
        val stream = Stream(url, (best["mimeType"] as? String) ?: "audio/mp4", size)
        synchronized(this) { streams[token] = stream }
        return stream
    }

    private fun copy(
        input: InputStream,
        out: OutputStream,
    ): Long {
        val buffer = ByteArray(64 * 1024)
        var total = 0L
        while (true) {
            val n = input.read(buffer)
            if (n < 0) break
            out.write(buffer, 0, n)
            total += n
        }
        return total
    }

    /** A single `bytes=a-b` / `bytes=a-` range, clamped to the file; the whole file without one. */
    private fun parseRange(
        header: String?,
        size: Long,
    ): Pair<Long, Long> {
        val spec = header?.removePrefix("bytes=")?.substringBefore(',') ?: return 0L to size - 1
        val start = spec.substringBefore('-').toLongOrNull()
        val end = spec.substringAfter('-').toLongOrNull()
        return when {
            start == null && end != null -> maxOf(0, size - end) to size - 1
            else -> (start ?: 0L).coerceIn(0, size - 1) to minOf(end ?: (size - 1), size - 1)
        }
    }

    private fun writeRangeHead(
        out: OutputStream,
        partial: Boolean,
        start: Long,
        end: Long,
        size: Long,
        mime: String,
    ) {
        val headers =
            buildMap {
                put("Content-Type", mime)
                put("Content-Length", (end - start + 1).toString())
                put("Accept-Ranges", "bytes")
                if (partial) put("Content-Range", "bytes $start-$end/$size")
                // DLNA renderers (e.g. Samsung TVs) want these to allow seeking and streaming.
                put("contentFeatures.dlna.org", DLNA_FEATURES)
                put("transferMode.dlna.org", "Streaming")
            }
        if (partial) writeHead(out, 206, "Partial Content", headers) else writeHead(out, 200, "OK", headers)
    }

    private fun writeHead(
        out: OutputStream,
        code: Int,
        reason: String,
        headers: Map<String, String>,
    ) {
        val text =
            buildString {
                append("HTTP/1.1 $code $reason\r\n")
                headers.forEach { (k, v) -> append("$k: $v\r\n") }
                append("Access-Control-Allow-Origin: *\r\n")
                append("Connection: close\r\n\r\n")
            }
        out.write(text.toByteArray(Charsets.ISO_8859_1))
    }

    private fun readLine(input: InputStream): String? {
        val line = StringBuilder()
        while (true) {
            val c = input.read()
            if (c < 0) return if (line.isEmpty()) null else line.toString()
            if (c == '\n'.code) return line.toString().trimEnd('\r')
            line.append(c.toChar())
            if (line.length > 8192) return null
        }
    }

    private fun mimeOf(file: File) = if (file.extension.equals("webm", ignoreCase = true)) "audio/webm" else "audio/mp4"

    /** This phone's IPv4 address on the local network (Wi-Fi first). */
    private fun lanAddress(): String? {
        val candidates =
            NetworkInterface
                .getNetworkInterfaces()
                ?.toList()
                .orEmpty()
                .filter { it.isUp && !it.isLoopback }
                .sortedByDescending { it.name.startsWith("wlan") }
        return candidates
            .flatMap { it.inetAddresses.toList() }
            .firstOrNull { it is Inet4Address && it.isSiteLocalAddress }
            ?.hostAddress
    }
}
