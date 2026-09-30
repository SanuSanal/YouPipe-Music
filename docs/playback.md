# Playback (`lib/player/`)

## YouPipeAudioHandler

`BaseAudioHandler with SeekHandler` wrapping one `just_audio` `AudioPlayer`. It provides background playback, the notification, lockscreen and headset controls, and Android Auto.

- **The queue lives in the handler** as `ValueNotifier<QueueState>` (songs, index, shuffle, repeat, title). audio_service's `queue`/`mediaItem` are kept in sync for the system UI. The UI reads it through `queueStateProvider`, `currentSongProvider`, `playbackStateProvider` and `positionProvider`.
- **The current song plus the next one** are loaded, not the whole queue, because stream URLs expire and are resolved lazily. `_loadIndex` loads a song:
  1. If `localFile(videoId)` finds a download, play that file.
  2. Otherwise resolve the stream URL.
  3. Call `setAudioSource`, play, and preload the next song (`_syncPreloaded`).
- **Preloading the next song (gapless):** on the phone's own player, just_audio's playlist is `[current, upcoming]`. ExoPlayer buffers the upcoming song before the current one ends and moves on with no gap.
  - `_upcomingIndex()` is the next queue index, or `0` with repeat-all at the end. It's null with repeat-one, with sleep-at-end-of-song, or at the end of the queue; then nothing is preloaded and `_onCompleted` handles the end as before.
  - `_syncPreloaded()` rebuilds the second slot. It runs after every queue edit, shuffle, repeat or sleep-at-end change. The work is serialized on `_preloadOp` and guarded by `_loadGeneration`.
  - When preloading fails (for example with no signal), it's logged and tried again every 20 s for as long as the same song plays.
  - `_onPlayerIndex` (on `currentIndexStream`) handles the automatic move: it publishes the new queue index, media item and SponsorBlock segments, then preloads the one after.
  - Skipping to the preloaded song (Next, SponsorBlock ending a song, tapping it in Up next) uses `seekToNext()` in place of a reload.
  - Cast and video mode don't preload; their `_loadIndex` path is unchanged.
- **Stale-load guard:** `_loadGeneration` makes sure a slow load can't override a newer choice.
- **Error recovery (tested 2026-09-30 by turning Wi-Fi off and on while playing):**
  - **Where errors arrive:** just_audio 0.10 reports player errors on `errorStream`, not as errors on `playbackEventStream`. The old `onError` hook never fired, so nothing recovered.
  - **Retrying:** a player error, or a failed load that can be retried, calls `_recover`. It clears **every** cached stream URL (they're bound to the phone's IP, which usually changes after a loss of signal), then reloads the song with a fresh URL from `_lastPosition`. The first retry is immediate, then after 2, 5, 10, 20 and 30 s (`_retryDelays`, about 3.5 minutes in all). After that it shows the error state ("Can't play this song").
  - **While retrying,** the session reports `buffering` and playing, so the car and notification don't look stopped. Pause cancels the retries; Play (also from the error or idle state) retries at once.
  - **Not retried:** `AGE_RESTRICTED`, `GEO_RESTRICTED`, `UNAVAILABLE` and `NO_STREAMS` go straight to the error state.
  - **The retry count** resets after 20 s of playback past the recovery point.
  - **No double counting:** `_settingSource` and the pending retry timer stop one failure being handled twice (by `_loadIndex`'s catch and by `errorStream`).
  - **A preloaded next song that fails** as the player reaches it is recovered as that song, from 0:00.
- **Buffer:** `AndroidLoadControl` buffers 3–5 minutes ahead instead of ExoPlayer's 50 s. That's a few MB at 160 kbps, and short losses of signal pass unnoticed. In the test, 40 s without Wi-Fi played through, including the move into the preloaded next song.
- **Swiping the app away** from recent apps stops playback, the notification and the service (`onTaskRemoved` → `stop()`). audio_service's default does nothing, so before this the music kept playing with the app gone. Reopening the app and pressing play starts the song again.
- **Completion:** repeat-one replays; otherwise the next song plays; with repeat-all at the end it wraps; otherwise it stops at 0. When the next song wasn't preloaded (for example because preloading failed), it's loaded with a fresh URL (`_loadNext`).
- **Error log:** failures (player, load, preload, radio, video, download, cast, uncaught) go to the in-memory `errorLog` (`lib/data/error_log.dart`, last 200 entries), which the hidden Error log page shows (see ui.md).
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
  - Skips are silent: no toast.
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

## Outputs and video mode

- **Outputs:** songs play on one output at a time. It's picked in `_syncOutput`:
  1. the **Cast device** while casting;
  2. otherwise the **video output** in video mode;
  3. otherwise the phone's own just_audio player.
- **Shared routing:** the Cast device and the video output are both `RemotePlayback`s on the same path.
  - `_loadIndex` loads on them.
  - `play`, `pause`, `seek`, position, completion and `playbackState` follow them.
  - Switching outputs pauses the old one and continues on the new one from the same position, keeping it playing if it was. The one exception: when casting ends, the phone is left paused, as YTM does.
- **Video mode** (the full player's Song/Video toggle, `handler.setVideoMode`, `videoModeProvider`):
  - `VideoOutput` (`lib/player/video_output.dart`) plays the song's music video (see innertube.md, "Music videos") with `video_player` (ExoPlayer).
  - **Quality** (setting `videoQuality`): `auto` plays a local DASH manifest of the 360p–1080p video-only streams (it starts low and steps up) plus the audio, and ExoPlayer picks the height by bandwidth. `high` keeps only the tallest one up to 1080p. `dataSaver` plays the muxed 360p stream. When there's no HD (`NO_HD`, or the manifest fails to initialize) it falls back to 360p. See streaming.md.
  - Options: `allowBackgroundPlayback: true` (the video keeps playing as sound in the background, so the notification and lock screen player carry on) and `mixWithOthers: true` (no audio-focus fight with just_audio).
  - **Next / auto-advance** stay in video mode.
  - **A song without a video** falls back to the song (`handler.noVideo`, toast "No video for this song").
  - **Casting** turns video mode off.
  - **Full screen:** see ui.md.
  - **SponsorBlock** loads segments for the video's own id.
  - **Downloads** don't apply: video mode always streams.
  - Planned next: song↔video position alignment (music videos often have a longer intro than the song).

## Android Auto (`auto_browser.dart`)

- The handler's `getChildren`, `playFromMediaId`, `search` and `playFromSearch` delegate to `AutoBrowser`, which `autoBrowserProvider` sets up.
- **Media ids:**
  - Browsable: `folder:home|liked|downloads|playlists|history`, `home:<n>`, `playlist:<id>`, `album:<id>`, `local:<id>`.
  - Playable: `<parentId>|<index>` plays the whole list from that index; `song:<videoId>` (search results) starts a radio.
- Manifest: `com.google.android.gms.car.application` → `res/xml/automotive_app_desc.xml`.
- Covered by `test/auto_browser_test.dart`. Tested on a real car on 2026-09-30: playback, and the app in the car's launcher.
- **Sideloaded builds are hidden from the car's launcher.** Android Auto only lists apps installed from the Play Store until the user turns on **Unknown sources**: open Android Auto's settings, tap **Version** about 10 times, then go to ⋮ → **Developer settings** → **Unknown sources**. The app may also need adding with **Customize launcher**. Without this, playback still shows in the car, because Android Auto displays any active media session as "now playing". The app can't change this, so the step is in the README and the website FAQ.
