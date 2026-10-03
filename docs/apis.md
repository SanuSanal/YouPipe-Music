# APIs used by the app

Every network API and native channel YouPipe Music talks to, in one place. This page lists *what* is called and with which parameters. The linked docs explain *why* and how the responses are parsed.

Nothing here is secret. There are no API keys in the app. The YouTube calls are the same ones the YouTube Music website makes, and other open-source clients (ytmusicapi, NewPipe, SimpMusic) document them too. **Never add real cookies, tokens or signed-in responses to this page.**

## Overview

| Service | Host | Used for | Auth | Code |
|---|---|---|---|---|
| YouTube Music InnerTube | `music.youtube.com/youtubei/v1` | Browse, search, queue, lyrics, account and library sync | None, or the Google session cookie | `lib/innertube/` |
| YouTube streams (NewPipeExtractor) | `youtube.com`, `googlevideo.com` | Playable audio/video URLs, playback, downloads | None | `StreamExtractorChannel.kt`, `PlaybackProxy.kt`, `DownloadChannel.kt` |
| Google sign-in | `accounts.google.com` | The user signs in inside a WebView | The user's own credentials | `lib/features/settings/login_screen.dart` |
| Image CDNs | `*.googleusercontent.com`, `i.ytimg.com` | Cover art and thumbnails | None | `lib/innertube/models.dart` (`Thumbnail`) |
| LRCLIB | `lrclib.net/api` | Synced lyrics | None | `lib/data/lyrics/lyrics_service.dart` |
| SponsorBlock | `sponsor.ajay.app/api` | Skipping non-music segments | None | `lib/data/sponsorblock.dart` |
| GitHub Releases | `api.github.com`, `github.com` | The in-app updater | None | `lib/data/updater.dart` |
| Google Cast SDK | Local network | Casting to Chromecast | None | `CastChannel.kt`, `CastOptionsProvider.kt` |
| DLNA / UPnP AV | Local network | Casting to smart TVs and speakers | None | `lib/player/dlna.dart` |

## YouTube Music InnerTube

Detailed parsing and response quirks are in [innertube.md](innertube.md). Signed-in behaviour is in [account.md](account.md).

### Request format

- **Every call** is `POST https://music.youtube.com/youtubei/v1/<endpoint>?prettyPrint=false` with a JSON body.
- **Client identity:** `WEB_REMIX` (YouTube Music web), from `YouTubeClient.webRemix` in `lib/innertube/clients.dart`. The `clientVersion` drifts; refresh it when YouTube starts rejecting requests.
- **Headers:** `User-Agent` (desktop Chrome), `X-YouTube-Client-Name: 67`, `X-YouTube-Client-Version`, `Origin` and `Referer: https://music.youtube.com`, and `X-Goog-Visitor-Id` once known.
- **Body:** every request merges the endpoint's fields into this context:

  ```json
  {
    "context": {
      "client": { "clientName": "WEB_REMIX", "clientVersion": "<version>", "hl": "en", "gl": "US", "visitorData": "<visitorData>" }
    }
  }
  ```

  `hl` and `gl` come from Settings.
- **visitorData** is an anonymous session id. The app gets it from `POST visitor_id` with an empty body (or from `responseContext.visitorData` of the first response), then stores it in prefs. Without it YouTube serves generic responses.
- **Continuations:** send `{"continuation": "<token>"}` to the same endpoint (`browse`, `search` or `next`). See [innertube.md](innertube.md) for where the tokens come from.

### Signed-in headers

These are only added when the stored cookie contains `SAPISID` or `__Secure-3PAPISID` (`lib/innertube/auth.dart`):

| Header | Value |
|---|---|
| `Cookie` | The Google session cookie read from the sign-in WebView |
| `Authorization` | `SAPISIDHASH <ts>_<sha1("<ts> <SAPISID> https://music.youtube.com")>`, where `ts` is Unix time in **seconds** |
| `X-Goog-AuthUser` | `0` |
| `X-Origin` | `https://music.youtube.com` |

### Endpoints

| Dart method (`InnerTube`) | Endpoint | Body fields (besides `context`) | Needs sign-in |
|---|---|---|---|
| `ensureVisitorData()` | `visitor_id` | none | no |
| `home({chip})` | `browse` | `browseId: FEmusic_home` (or the chip's `browseId` + `params`) | no |
| `explore()` | `browse` | `browseId: FEmusic_explore` | no |
| `browseSections(ep)` | `browse` | `browseId`, `params` from the "More", chart, new-release or mood endpoint | no |
| `album(id)` | `browse` | `browseId: MPREb_…` | no |
| `artist(id)` | `browse` | `browseId: UC…` | no |
| `playlist(id)` | `browse` | `browseId: VL<playlistId>` | no |
| `lyrics(ep)` / `related(ep)` | `browse` | `browseId: MPLY…` / `MPTR…` (taken from the `next` response tabs) | no |
| `sectionsContinuation`, `playlistContinuation` | `browse` | `continuation` | no |
| `search(q, filter)` | `search` | `query`, `params` (filter blob from `SearchFilter`). A Videos search also finds a song's music video, for video mode and for playing an unavailable song's audio | no |
| `searchContinuation` | `search` | `continuation` | no |
| `searchSuggestions(input)` | `music/get_search_suggestions` | `input` | no |
| `next(ep)` | `next` | `videoId`, `playlistId`, `params`, `index`, `isAudioOnly: true`, `enablePersistentPlaylistPanel: true`, `tunerSettingValue: AUTOMIX_SETTING_NORMAL` | no |
| `nextContinuation` | `next` | `continuation`, `playlistId`, `isAudioOnly: true`, `enablePersistentPlaylistPanel: true` | no |
| `accountInfo()` | `account/account_menu` | none | yes |
| `library(page)` | `browse` | `browseId: FEmusic_liked_playlists`, `FEmusic_liked_videos`, `FEmusic_liked_albums`, `FEmusic_library_corpus_track_artists` or `FEmusic_library_corpus_artists` | yes |
| `like` / `removeLike` | `like/like` / `like/removelike` | `target: {videoId}` | yes |
| `savePlaylist(id, save:)` | `like/like` / `like/removelike` | `target: {playlistId}` (albums use their playlist id) | yes |
| `subscribe(id, subscribe:)` | `subscription/subscribe` / `subscription/unsubscribe` | `channelIds: [id]` | yes |
| `createPlaylist` | `playlist/create` | `title`, `privacyStatus: PRIVATE`, optional `videoIds` | yes |
| `addToPlaylist` | `browse/edit_playlist` | `playlistId` (without `VL`), `actions: [{action: ACTION_ADD_VIDEO, addedVideoId}]` | yes |
| `feedback(tokens)` | `feedback` | `feedbackTokens` (the "Save to / Remove from library" tokens from row menus) | yes |

### ID prefixes

| Prefix / id | Meaning |
|---|---|
| `FEmusic_…` | Built-in pages (home, explore, library pages) |
| `MPREb_…` | Album |
| `UC…` | Artist / channel |
| `VL<playlistId>` | Playlist page (the browse id is `VL` + the playlist id) |
| `RDAMVM<videoId>` | Radio for a song (`next` with this `playlistId`) |
| `MPLY…` / `MPTR…` | Lyrics / Related tab of the player |
| `LM` / `SE` | The account's Liked Music / Episodes for Later playlists |

## YouTube streams (NewPipeExtractor)

The app does **not** use InnerTube `/player`. Without a PO token, its URLs stop at about 1 MB. Playable URLs come from [NewPipeExtractor](https://github.com/TeamNewPipe/NewPipeExtractor) (`com.github.TeamNewPipe:NewPipeExtractor:v0.26.5` from JitPack, set in `android/app/build.gradle.kts`). It runs in Kotlin with its own OkHttp downloader and calls YouTube for `https://www.youtube.com/watch?v=<videoId>`. Details are in [streaming.md](streaming.md).

- **The resulting googlevideo URLs** carry `ip=` (the phone's IP), `c=` (the client that produced them) and `expire=`. They only work from the same IP, with a User-Agent that matches `c=`.
- **Phone playback, downloads and the cast relay** fetch them in 1 MB `Range` chunks (`Googlevideo.kt`). Phone playback goes through `PlaybackProxy.kt` on 127.0.0.1, because googlevideo throttles the player's own single open-ended request (see streaming.md).

## Google sign-in

- `LoginScreen` opens `https://accounts.google.com/ServiceLogin?ltmpl=music&service=youtube&…` (it continues to music.youtube.com) in a WebView. The user types their own credentials.
- Once a page on `https://music.youtube.com` loads, the app reads the cookie jar through the `youpipe/cookies` channel and stores the cookie in secure storage.
- No OAuth client or API key is involved. See [account.md](account.md).

## LRCLIB (lyrics)

Base `https://lrclib.net/api/`, with the header `User-Agent: YouPipe Music/1.0 (Android; https://github.com/youpipe-music)`.

| Call | Query | Notes |
|---|---|---|
| `GET get` | `track_name`, `artist_name`, `album_name` (when known), `duration` (seconds) | Exact match. A 404 means no match. |
| `GET search` | `track_name`, `artist_name` | Fallback. The app picks the result closest in duration, preferring synced lyrics. |

The response fields used are `syncedLyrics` (LRC), `plainLyrics`, `instrumental` and `duration`. If LRCLIB has nothing, the app falls back to YouTube's own lyrics (`browse MPLY…`).

## SponsorBlock

`GET https://sponsor.ajay.app/api/skipSegments/<prefix>?categories=["music_offtopic"]&actionType=skip`

- `<prefix>` is the first 4 hex characters of `sha256(videoId)`. This is a privacy-preserving lookup: the server never sees which video is playing, and the app picks its video from the returned list by `videoID`.
- Each `segments[].segment` is a `[start, end]` pair in seconds. Segments shorter than 1 s are ignored.

## GitHub Releases (updater)

- `GET https://api.github.com/repos/SanuSanal/YouPipe-Music/releases/latest` with `Accept: application/vnd.github+json`.
- The fields used are `tag_name`, `body`, `html_url` and `assets[]` (`name`, `browser_download_url`, `size`, `digest` as `sha256:<hex>`).
- The APK is downloaded from `browser_download_url` and checked against the digest. See [updates.md](updates.md).

## Casting (local network)

Details are in [cast.md](cast.md).

- **Chromecast:** uses the Google Cast SDK with Google's **Default Media Receiver**, so there's no receiver app id to register.
- **DLNA:**
  - Discovery is SSDP `M-SEARCH` for `urn:schemas-upnp-org:device:MediaRenderer:1`, after which the app reads each device description.
  - Control is SOAP: AVTransport `SetAVTransportURI` (with DIDL-Lite metadata), `Play`, `Pause`, `Seek` (REL_TIME), `Stop`, `GetTransportInfo` and `GetPositionInfo`, plus RenderingControl `SetVolume`.
- **LAN relay:** TVs can't fetch IP-bound googlevideo URLs, so `CastProxy.kt` serves the audio from the phone at `http://<phone-ip>:<port>/a/<token>`.

## Share links

`lib/ui/widgets/item_menu.dart` builds public music.youtube.com links: `/watch?v=<videoId>`, `/playlist?list=<playlistId>`, `/browse/<albumBrowseId>` and `/channel/<artistBrowseId>`.

## Platform channels (Dart ↔ Kotlin)

These are internal APIs between Flutter and `android/app/src/main/kotlin/com/youpipe/music/`.

| Channel | Methods (arguments → result) | Kotlin |
|---|---|---|
| `youpipe/stream_extractor` | `getAudioStreams({videoId, hl, gl})` → `{videoId, durationSeconds, streams: [{url, itag, mimeType, codec, bitrate, contentLength}]}`; `getVideoStream({videoId, hl, gl})` → `{url, height, mimeType, userAgent, durationSeconds}`; `getVideoManifest({videoId, hl, gl, maxHeight, onlyBest})` → `{mpd, height, userAgent, durationSeconds}`. Error codes are listed in [streaming.md](streaming.md). | `StreamExtractorChannel.kt` |
| `youpipe/playback_proxy` | `url({url, mimeType, contentLength})` → `http://127.0.0.1:<port>/s/<token>`, which serves that googlevideo URL to the phone's player | `PlaybackProxy.kt` |
| `youpipe/downloader` | `download({id, url, path})` → int; `cancel({id})` | `DownloadChannel.kt` |
| `youpipe/downloader/progress` (events) | `{id, downloaded, total}` | `DownloadChannel.kt` |
| `youpipe/cookies` | `get({url})` → cookie string; `clear()` | `CookieChannel.kt` |
| `youpipe/effects` | `attach({session})` → `{session, eq, loudness}`; `setEqEnabled({enabled})`; `setGains({gains})`; `setLoudness({db})`; `release()` | `AudioEffectsChannel.kt` |
| `youpipe/updater` | `appInfo()` → `{versionName, versionCode, abis, device}`; `install({path})`; `openUrl({url})` | `UpdateChannel.kt` |
| `youpipe/cast` | `selectRoute({id})`, `load({videoId, localPath, title, artist, album, artUrl, durationMs, positionMs, autoplay})`, `play`, `pause`, `seek({positionMs})`, `setVolume({volume})`, `disconnect`; relay: `relayStart`, `relayUrl({videoId, localPath})` → `{url, contentType}`, `relayStop` | `CastChannel.kt` |
| `youpipe/cast/events` (events) | `{type: routes, routes}`, `{type: state, state, device, volume}`, `{type: player, state, url, …}` | `CastChannel.kt` |
| `youpipe/lockscreen` | `canDrawOverlays()` → bool; `requestOverlay()` | `LockScreenLauncher.kt` |

## Terms and stability

- **InnerTube is unofficial and undocumented.** YouTube can change it without notice, and using it is subject to YouTube's Terms of Service. When requests start failing, see the client-version note in [innertube.md](innertube.md) and the NewPipeExtractor note in [streaming.md](streaming.md).
- **LRCLIB, SponsorBlock and GitHub** are public APIs with their own usage terms and rate limits. Keep requests cached and modest (both lyrics and SponsorBlock results are cached per video).
- **Keep this page current:** when you add, remove or change a call, update it in the same change (see `/AGENTS.md`).
