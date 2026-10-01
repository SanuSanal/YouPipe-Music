# Performance and memory

Conventions that keep the app light, and how to measure it. Read this when you add a widget that shows per-song state, an image, a database table that grows, or anything that ticks.

## Conventions

- **Per-row state uses `select`.** A song row must not rebuild when another song changes.
  - Watch a bool, not the shared collection: `ref.watch(downloadedIdsProvider.select((ids) => ids.contains(id)))`, `ref.watch(currentSongProvider.select((s) => s?.videoId == id))`. Pages showing "all downloaded" select that bool too.
  - Providers keyed by song id are `autoDispose` (e.g. `downloadStatusProvider`), so menus opened over a session don't stay alive.
- **Derived sets come from narrow, distinct streams.**
  - `downloadedIdsProvider` reads `DownloadManager.watchDoneIds()`, which selects only finished ids and is `.distinct(setEquals)`.
  - The downloads table is written every 400 ms with progress, and the `songs` table on every song change, so a stream over the full join would re-emit constantly.
- **Things that tick rebuild small.**
  - Only `SeekBar` and `SongProgressBar` watch `positionProvider` directly.
  - Synced lyrics select the active line index, so they rebuild once per line.
- **Images are decoded at their display size.** `YtImage` passes `memCacheHeight` (network) and `cacheHeight` (files) set to the box height in device pixels. YouTube video thumbnails and saved artwork come at fixed sizes and would otherwise be decoded at full resolution in 48 px rows.
- **Tables that grow per action are capped.** `PlayHistory` keeps the newest 2000 plays (see data.md).
- **The media session gets the queue only when it changes.** `_publish` skips `queue.add` when only the index moved (see playback.md).
- **One OkHttp client.** Kotlin builds clients from `Googlevideo.client` (`newBuilder()` or as-is), so they share one connection pool and dispatcher.
- **Clean up what you subscribe to.** Cancel stream subscriptions and close controllers when their owner goes away (e.g. the DLNA session in `CastController.disconnect`). Dialogs own their `TextEditingController` in a `State` (see `_PromptDialog`).

## Measuring

Use a **profile** build (`flutter build apk --profile`). It's debug-signed, so it installs over a debug build without losing app data.

- **Memory:** `adb shell dumpsys meminfo com.youpipe.music`. Watch `Graphics` (decoded images and GPU buffers), `Native Heap` and `TOTAL PSS`. To find leaks, repeat an action (open and close a page 20 times): PSS should level off, not climb with each loop.
- **Frames:**
  - `dumpsys gfxinfo` only counts Android view frames, not Flutter's.
  - For Flutter frame cost, temporarily log `FrameTiming`s from `SchedulerBinding.instance.addTimingsCallback` (build and raster durations) per 5 s window. Don't commit it.
  - `dumpsys SurfaceFlinger --latency 'SurfaceView[com.youpipe.music/…](BLAST)#N'` counts the frames the Flutter surface presented.
- **Scripting the UI:** Flutter's semantics show up in `adb shell uiautomator dump` as `content-desc`. Find a widget by its label and tap the centre of its bounds. Set `MSYS_NO_PATHCONV=1` in Git Bash so `/sdcard/...` isn't rewritten. The expanded player panel isn't in the dump; use coordinates there.
- **Unit tests** guard the conventions above: `test/performance_test.dart`.

## Review of 2026-10-01

Measured on the test phone (1080×2400, 144 Hz), comparing a profile build of `main` with the fixes:

| Measurement | Before | After |
|---|---|---|
| Graphics memory after three searches (2 runs each) | 180–184 MB | 111–112 MB |
| Total PSS after three searches | 379–396 MB | 309–310 MB |
| Synced lyrics: average build time per frame | 6.3 ms | 4.2 ms |
| Open/close a playlist 20 times | PSS flat | PSS flat |

- **Downloads:** the per-row fix is proven by `test/performance_test.dart`. On the phone, the three test songs finished within seconds, so the idle-page frame numbers barely moved.
- **Found while measuring:** a wedge in just_audio's Android player after a failed load raced a preload edit (see playback.md, "Playlist edits go through `_edit`").
