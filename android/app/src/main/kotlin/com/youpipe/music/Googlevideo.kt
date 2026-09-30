package com.youpipe.music

import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import org.schabi.newpipe.extractor.services.youtube.YoutubeParsingHelper
import java.util.concurrent.TimeUnit

/**
 * Fetching from googlevideo stream URLs, shared by the downloader and the cast proxy.
 *
 * Stream URLs are bound to this phone's IP and to the InnerTube client that produced them: requests
 * must leave through this device, with that client's User-Agent, in ranges of at most about 1 MB
 * (docs/streaming.md).
 */
object Googlevideo {
    const val CHUNK = 1024L * 1024L

    private const val WEB_USER_AGENT =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0"

    val client: OkHttpClient =
        OkHttpClient
            .Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()

    fun userAgentFor(url: String): String =
        when {
            YoutubeParsingHelper.isVisionOsStreamingUrl(url) -> YoutubeParsingHelper.getVisionOsUserAgent(null)
            YoutubeParsingHelper.isAndroidStreamingUrl(url) -> YoutubeParsingHelper.getAndroidUserAgent(null)
            YoutubeParsingHelper.isIosStreamingUrl(url) -> YoutubeParsingHelper.getIosUserAgent(null)
            else -> WEB_USER_AGENT
        }

    /** One range request (`start`..`endInclusive`); the caller closes the response. */
    fun range(
        url: String,
        start: Long,
        endInclusive: Long,
    ): Response =
        client
            .newCall(
                Request
                    .Builder()
                    .url(url)
                    .header("User-Agent", userAgentFor(url))
                    .header("Range", "bytes=$start-$endInclusive")
                    .build(),
            ).execute()

    /** The full size from a range response (`Content-Range: bytes a-b/total`). */
    fun totalSize(response: Response): Long? =
        response.header("Content-Range")?.substringAfterLast('/')?.toLongOrNull()
            ?: response.body?.contentLength()?.takeIf { it > 0 }
}
