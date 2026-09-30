# Playback (`lib/player/`)

## YouPipeAudioHandler

`BaseAudioHandler with SeekHandler` wrapping one `just_audio` `AudioPlayer`. It provides background playback, the notification, lockscreen and headset controls, and Android Auto.

- **The queue lives in the handler** as `ValueNotifier<QueueState>` (songs, index, shuffle, repeat, title). audio_service's `queue`/`mediaItem` are kept in sync for the system UI. The UI reads it through `queueStateProvider`, `currentSongProvider`, `playbackStateProvider` and `positionProvider`.
- **One song is loaded at a time** (`_loadIndex`), not a just_audio playlist, because stream URLs expire and are resolved lazily. Order of work:
  1. If `localFile(videoId)` finds a download, play that file.
  2. Otherwise resolve the stream URL.
  3. Call `setAudioSource`, play, and pre-resolve the next song (`_prefetchNext`).
- **Stale-load guard:** `_loadGeneration` makes sure a slow load can't override a newer choice.
- **Error recovery:** a player error fetches a new URL once and resumes at the same position (`_retriedCurrent`). Pressing play in the error state retries.
- **Completion:** repeat-one replays; otherwise the next song plays; with repeat-all at the end it wraps; otherwise it stops at 0.
- **Shuffle works like YouTube Music:** turning it on *reorders the upcoming songs in the visible queue*. It isn't a hidden shuffle order. Turning it off doesn't restore the old order.
- **Queue edits:** `playNext`, `addToQueue`, `removeFromQueue` (the current song can't be removed) and `moveInQueue` (keeps `index` pointing at the current song; the arguments use `ReorderableListView.onReorderItem` semantics).
- **Our enum is `QueueRepeatMode`,** not `RepeatMode`, which now clashes with a Flutter widgets type.

## Radio and autoplay (`PlayerActions` in `providers.dart`)

- **Tapping a single song** plays it immediately, then adds its radio (`next` with `playlistId: RDAMVM<videoId>`, first item skipped) through a `QueueExtender`. YouTube Music does the same.
- **Topping up:** the handler calls the extender when 5 or fewer songs remain, following `next` continuations. An empty result ends the radio.
- **Other entry points:**
  - `playList(songs, index, shuffle, title)` plays albums, playlists and library lists (no extender).
  - `playEndpoint(WatchEndpoint)` plays the artist Shuffle/Mix buttons and radio cards.
- The queue `title` ("Radio", the album name…) is shown as "Playing from" in Up next.

## Extras

- **SponsorBlock:**
  - When the `skipNonMusic` setting is on, `segmentLoader` fetches the `music_offtopic` segments (`lib/data/sponsorblock.dart`). It uses the privacy-preserving hash-prefix endpoint, sending only the first 4 hex chars of sha256(videoId).
  - The position stream seeks past a segment; a segment that reaches the end counts as song completion.
  - Each skip is emitted on `skippedSegments`, which the shell shows as a toast.
- **Sleep timer:** `setSleepTimer(duration)` fades out over about 5 s and then pauses. `sleepAtEndOfSong()` pauses on completion instead of advancing. State is in `sleepTimer` (`sleepTimerProvider`).
- **Speed:** `setSpeed` (overrides BaseAudioHandler) with `speedProvider`.
- **Equalizer and loudness:**
  - Uses `AndroidEqualizer` and `AndroidLoudnessEnhancer` in the player's `AudioPipeline`. Band parameters only exist once the player is active, so gains are applied from `equalizer.parameters`.
  - `AudioEffectsController` persists `eqEnabled`, `eqGains`, `loudnessDb` and `eqPreset`, and restores them at startup.
  - Presets are **gain curves over frequency** (`eqPresets`), so they fit any device's band layout.
- **History:** the app shell records each new current song in the local history when `saveHistory` is on.
- **Lyrics:**
  - `LyricsService` tries LRCLIB first (`/api/get` with the duration, then `/api/search` with ±4 s duration matching, preferring synced results). Titles are cleaned with `cleanTitle`/`cleanArtist`.
  - It falls back to YouTube Music's plain lyrics.
  - LRC is parsed by `lrc.dart`; the active line is found with a binary search (`activeLineIndex`) plus a 250 ms lead.

- **Lock screen player:** an opt-in activity over the keyguard, driven by the media session. Its Like and Repeat buttons are the custom actions `toggleLike`/`cycleRepeat` (`customAction`). See [lockscreen.md](lockscreen.md).

- **Casting (Chromecast, DLNA):** while a device is connected, `_loadIndex` loads songs on it and the transport follows it (`handler.cast`). See [cast.md](cast.md).

## Android Auto (`auto_browser.dart`)

- The handler's `getChildren`, `playFromMediaId`, `search` and `playFromSearch` delegate to `AutoBrowser`, which `autoBrowserProvider` sets up.
- **Media ids:**
  - Browsable: `folder:home|liked|downloads|playlists|history`, `home:<n>`, `playlist:<id>`, `album:<id>`, `local:<id>`.
  - Playable: `<parentId>|<index>` plays the whole list from that index; `song:<videoId>` (search results) starts a radio.
- Manifest: `com.google.android.gms.car.application` → `res/xml/automotive_app_desc.xml`.
- Covered by `test/auto_browser_test.dart`. **It has not been run on a car or the Desktop Head Unit (DHU) yet.**
