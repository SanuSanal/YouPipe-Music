# Streams and downloads

## Why NewPipeExtractor (decision, tested 2026-09-29)

- InnerTube `/player` with the `IOS` or `ANDROID` client (plus `visitorData`) returns direct audio URLs. **Without a PO token, googlevideo serves only the first ~1 MB** (about 60 s of audio): any range past that, or the whole file, returns 403.
- Other clients failed outright: `ANDROID_VR` and `ANDROID_MUSIC` gave `LOGIN_REQUIRED`, `TVHTML5_SIMPLY` is "no longer supported", and web clients need signature/`n` deciphering and PO tokens.
- SimpMusic has the same problem and delegates to a NewPipe-family extractor. The user chose **NewPipeExtractor**, over writing our own BotGuard PO-token generator.
- NewPipeExtractor's current path without a PO provider: the ANDROID `reel/reel_item_watch` endpoint plus the VISIONOS client, with deciphering handled internally. The resulting URLs play in full.
- **When playback breaks,** bump `com.github.TeamNewPipe:NewPipeExtractor:<tag>` in `android/app/build.gradle.kts` (JitPack) before touching anything in Dart. NewPipeExtractor needs `coreLibraryDesugaring` (`desugar_jdk_libs_nio`).

## Stream resolution

- Kotlin `StreamExtractorChannel.kt`, method `youpipe/stream_extractor.getAudioStreams({videoId, hl, gl})`, returns `{videoId, durationSeconds, streams: [{url, itag, mimeType, codec, bitrate, contentLength}]}`. It keeps only progressive-HTTP streams on the ORIGINAL audio track.
  - Error codes: `AGE_RESTRICTED`, `GEO_RESTRICTED`, `UNAVAILABLE`, `RECAPTCHA`, `EXTRACTION_FAILED` (plus `NO_STREAMS` from Dart).
  - It uses its own OkHttp `Downloader` and runs on a 3-thread executor.
- `StreamResolver` (`lib/data/stream_resolver.dart`):
  - **Format choice:** prefers Opus/WebM, then the highest bitrate (or the lowest for `AudioQuality.low`).
  - **Caching:** caches per videoId until 10 minutes before the URL's `expire` parameter.
  - **Refresh:** `invalidate()` or `forceRefresh` fetch a new URL.
- The player fetches a new URL once when a stream errors mid-song (see playback.md).

## Stream URLs are bound to the client

- A googlevideo URL carries `ip=` (the phone's address, often **IPv6 on mobile data**) and `c=` (the InnerTube client, e.g. `VISIONOS`).
- Requests from a different IP get a 403, so **URLs can't be tested from the dev PC**. Debug on the device.
- **Downloads are done natively** (`DownloadChannel.kt`, `youpipe/downloader`) with OkHttp, the same Android network stack that did the extraction:
  - The User-Agent matches the `c=` client, using NewPipe's `YoutubeParsingHelper.is*StreamingUrl` and `get*UserAgent`.
  - The file is fetched in **1 MB `Range` chunks**.
  - Progress is reported on the `youpipe/downloader/progress` EventChannel; `cancel({id})` stops a download.
  - The earlier Dart/dio implementation got 403s intermittently, so don't move downloads back to Dart.
- `Googlevideo.kt` holds the User-Agent choice and the 1 MB range request, shared by the downloader and the cast proxy.
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
