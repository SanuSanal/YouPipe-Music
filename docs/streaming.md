# Streams and downloads

## Why NewPipeExtractor (decision, tested 2026-09-29)

- InnerTube `/player` with the `IOS` or `ANDROID` client (plus `visitorData`) returns direct audio URLs. **Without a PO token, googlevideo serves only the first ~1 MB** (about 60 s of audio): any range past that, or the whole file, returns 403.
- Other clients failed outright: `ANDROID_VR` and `ANDROID_MUSIC` gave `LOGIN_REQUIRED`, `TVHTML5_SIMPLY` is "no longer supported", and web clients need signature/`n` deciphering and PO tokens.
- SimpMusic has the same problem and delegates to a NewPipe-family extractor. The user chose **NewPipeExtractor**, over writing our own BotGuard PO-token generator.
- NewPipeExtractor's current path without a PO provider: the ANDROID `reel/reel_item_watch` endpoint plus the VISIONOS client, with deciphering handled internally. The resulting URLs play in full.
- **When playback breaks,** bump `com.github.TeamNewPipe:NewPipeExtractor:<tag>` in `android/app/build.gradle.kts` (JitPack) before touching anything in Dart. NewPipeExtractor needs `coreLibraryDesugaring` (`desugar_jdk_libs_nio`).

## Stream resolution

- Kotlin `StreamExtractorChannel.kt`, method `youpipe/stream_extractor.getAudioStreams({videoId, hl, gl})`, returns `{videoId, durationSeconds, streams: [{url, itag, mimeType, codec, bitrate, contentLength}]}` (`bitrate` in **kbps**). It keeps only progressive-HTTP streams on the ORIGINAL audio track.
  - **DRC copies are dropped:** YouTube also serves "stable volume" copies of some itags (`ItagItem.isDrc()`), with compressed dynamic range and almost the same bitrate. They're only kept when nothing else is offered (`originalAudio`). This applies to playback, downloads and the cast proxy.
  - Error codes: `AGE_RESTRICTED`, `GEO_RESTRICTED`, `UNAVAILABLE`, `RECAPTCHA`, `EXTRACTION_FAILED` (plus `NO_STREAMS` from Dart).
  - **`UNAVAILABLE` is YouTube's answer, not an extractor bug** (checked 2026-10-03). Some songs (e.g. nGBxfRSH6tE, beys6sH6L8U) return `playabilityStatus: UNPLAYABLE` "This video is not available" from `/player` for WEB_REMIX, IOS and ANDROID_VR alike, with gl IN or US. Bumping NewPipeExtractor won't help. A video upload of the same song usually plays, and the player falls back to it (see playback.md, "Unavailable songs").
  - It uses its own OkHttp `Downloader` and runs on a 3-thread executor.
- `StreamResolver` (`lib/data/stream_resolver.dart`):
  - **Format choice** (`StreamResolver.pick`, unit-tested): prefers Opus/WebM. `high` takes the highest bitrate (Opus 251, ~160 kbps), `normal` the highest at or below 100 kbps (250, ~70 kbps), `low` the lowest (249, ~50 kbps). Free YouTube tops out at 251; the 256 kbps streams need Premium.
  - **Caching:** caches per videoId until 10 minutes before the URL's `expire` parameter.
  - **Refresh:** `invalidate()` or `forceRefresh` fetch a new URL.
- The player fetches a new URL once when a stream errors mid-song (see playback.md).

- **Video mode:** `getVideoStream({videoId, hl, gl})` returns the best **muxed** progressive stream (video and audio in one file, at most 720p; YouTube only muxes **360p**, itag 18), plus the `userAgent` its client needs: `{url, height, mimeType, userAgent, durationSeconds}`, or `NO_VIDEO`. `StreamResolver.resolveVideo` caches it like audio. The `video_player` controller sends that User-Agent as a header.
- **HD video (tested 2026-09-30):** `getVideoManifest({videoId, hl, gl, maxHeight, onlyBest})` builds a static **DASH manifest** from the video-only progressive streams (H.264 preferred, VP9 when there's no H.264; one Representation per height from 360p up to `maxHeight`) plus the best non-DRC audio stream. Each Representation has its `BaseURL` and `SegmentBase` index/init byte ranges from `ItagItem`. It returns `{mpd, height, userAgent, durationSeconds}`, or `NO_HD` when there are no usable video-only streams or nothing at 480p or more.
  - `StreamResolver.resolveVideoManifest` writes the MPD to `<temp>/video/<videoId>_<quality>.mpd` and caches it until the URLs' `expire`.
  - **Why this works without a native player:** `video_player_android` sends every URI except `asset:`/`rtsp:` through `HttpVideoAsset`, whose `DefaultDataSource` wraps the header-carrying HTTP data source. So a `file://` MPD with `formatHint: VideoFormat.dash` plays in ExoPlayer, and its googlevideo requests carry the User-Agent. Re-check this when bumping `video_player`.

## Stream URLs are bound to the client

- A googlevideo URL carries `ip=` (the phone's address, often **IPv6 on mobile data**) and `c=` (the InnerTube client, e.g. `VISIONOS`).
- Requests from a different IP get a 403, so **URLs can't be tested from the dev PC**. Debug on the device.
- **Downloads are done natively** (`DownloadChannel.kt`, `youpipe/downloader`) with OkHttp, the same Android network stack that did the extraction:
  - The User-Agent matches the `c=` client, using NewPipe's `YoutubeParsingHelper.is*StreamingUrl` and `get*UserAgent`.
  - The file is fetched in **1 MB `Range` chunks**.
  - Progress is reported on the `youpipe/downloader/progress` EventChannel; `cancel({id})` stops a download.
  - The earlier Dart/dio implementation got 403s intermittently, so don't move downloads back to Dart.
- `Googlevideo.kt` holds the User-Agent choice and the 1 MB range request, shared by the downloader, the cast proxy and the playback proxy. `MiniHttp.kt` holds the bits of HTTP the two on-device servers share.
- **Phone playback goes through a loopback proxy** (`PlaybackProxy.kt`, added 2026-10-03).
  - **Why:** ExoPlayer reads a stream with one open-ended request, which googlevideo throttles to about 1.8× real time. The player's 3–5 minute buffer never filled: it was about 50 s ahead, so a short loss of signal stopped the music. Through 1 MB ranges with the client's User-Agent, a whole 5-minute song arrives in about 2 s. Measured on the phone over Wi-Fi.
  - **How:** `PlaybackProxy.uriFor` (Dart) registers the stream URL and gets `http://127.0.0.1:<port>/s/<token>` for `AudioSource.uri`. The server listens on 127.0.0.1 only (not `getLoopbackAddress()`, which is `::1` on Android) and serves only registered tokens (the last 16).
  - **Each 1 MB chunk is read in full before it's passed on,** so the upstream connection never sits idle while the player's buffer is full.
  - **The first chunk is fetched before the response head,** so googlevideo's refusal (403 for an expired URL or a changed IP address) or no network (502) reaches ExoPlayer as an HTTP error, and the player's recovery runs (playback.md). A failure mid-body closes the connection, and ExoPlayer asks again from where it is.
  - **Cleartext:** `res/xml/network_security_config.xml` allows plain HTTP to 127.0.0.1 only.
  - **Fallback:** if the channel fails, the handler plays the googlevideo URL directly (and logs it).
  - Video mode doesn't use it. The HD manifest asks for bounded byte ranges anyway, and the muxed 360p stream plays well above real time.
- **Cast devices** (Chromecast, DLNA TVs) can't fetch these URLs either, so the phone relays the audio over the LAN (`CastProxy.kt`, see [cast.md](cast.md)).
- Cover art (googleusercontent / i.ytimg) is not IP-bound, and is downloaded with dio.

## Download manager (`lib/data/download_manager.dart`)

- Downloads run one at a time from a queue:
  1. The `Downloads` row goes `queued` → `downloading`.
  2. A fresh URL is resolved (`forceRefresh`).
  3. The audio is saved natively to `<appSupport>/downloads/<videoId>.webm|m4a`, and the art with dio to `<videoId>.jpg`.
  4. The row goes to `done`. On error the partial file is deleted and the row is marked `failed`.
- **Progress** events are written to the DB at most every 400 ms; the UI watches the table.
- **Restarts:** `resumePending()` (called at app start) re-queues rows left `queued` or `downloading`.
- **Playback** prefers the local file through `audioHandler.localFile = manager.localPath`.
- **Limitation:** downloads run in the app process with no WorkManager, so they only progress while the app or the playback service is alive.
