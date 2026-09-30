# Architecture

## Layers

```
Flutter UI (lib/features/*, lib/ui/*)        Riverpod 3 providers (lib/providers.dart, lib/data/account.dart)
        │                                              │
        ▼                                              ▼
InnerTube client (lib/innertube/, pure Dart)    YouPipeAudioHandler (lib/player/) ── just_audio + audio_service
        │ dio → music.youtube.com/youtubei/v1          │ StreamResolver / DownloadManager (lib/data/)
        │                                              ▼
        │                                   Kotlin MethodChannels (android/.../com/youpipe/music/)
        │                                     youpipe/stream_extractor → NewPipeExtractor
        │                                     youpipe/downloader(+/progress) → OkHttp
        │                                     youpipe/cookies → WebView CookieManager
        ▼
Local data: drift SQLite (lib/data/db), SharedPreferences (settings), flutter_secure_storage (session cookie)
```

## Folder map

| Path | Role |
|---|---|
| `lib/main.dart` | Creates the services, starts `AudioService`, runs `ProviderScope` with overrides |
| `lib/providers.dart` | Core service providers, settings, audio effects, player actions, data providers (paged controllers) |
| `lib/innertube/` | InnerTube client, models, parsers (no Flutter imports, so tests run in plain Dart) |
| `lib/data/` | Stream resolver, downloads, lyrics (LRCLIB), SponsorBlock, drift DB, library repository, account/auth |
| `lib/player/` | `audio_handler.dart` (queue, playback, effects, timers); `auto_browser.dart` (Android Auto tree) |
| `lib/ui/` | Theme tokens, router, app shell (bottom nav + player panel), shared widgets, navigation helpers |
| `lib/features/<screen>/` | One folder per screen |
| `android/app/src/main/kotlin/com/youpipe/music/` | Native channels: stream extraction, downloader, cookies, updater, casting (Chromecast, and the LAN relay shared with DLNA); the lock screen player activity |
| `tool/` | Fixture recording and renderer-tree inspection scripts (Python) |

## Wiring and startup

- `main()` builds `InnerTube` (it restores `visitorData` from prefs), `StreamResolver`, `AudioService.init<YouPipeAudioHandler>` and `AppDatabase`. These are injected with `overrideWithValue` for `innerTubeProvider`, `streamResolverProvider`, `audioHandlerProvider`, `databaseProvider` and `prefsProvider`. Those providers throw if they aren't overridden.
- The audio handler is created **before** Riverpod exists, so providers push dependencies into it rather than the handler reading providers. The hooks it exposes are `segmentLoader` (SponsorBlock), `localFile` (downloads), `browser` (Android Auto) and `restoreAudioEffects`.
- `YouPipeApp` watches `settingsProvider`, `audioEffectsProvider`, `downloadManagerProvider` and `autoBrowserProvider`. Watching them at the root is what creates them and pushes those hooks into the handler at startup. If you add a provider with side effects, watch it there too.
- `HomeController` and `exploreProvider` await `authProvider.future`, so the first load is already personalised when a session exists.

## Conventions

- **Riverpod 3 without code generation.** Family notifiers take their argument through the constructor (`SearchController(this.arg)`), not `FamilyNotifier`. Use `autoDispose` for per-page data.
- **Plain immutable model classes**, not freezed/json_serializable. `YTItem` subclasses compare equal by `runtimeType` and `id`, so they're safe to use as family keys.
- **The InnerTube layer stays pure Dart.** Anything that needs the platform goes through `lib/data/` or a method channel.
- **Formatting:** `dart format -l 120`. The analyzer must report no issues (`flutter analyze`).
- **Paging** uses `Paged<T>` (value, continuation, loadingMore), and controllers expose `loadMore()`. Screens trigger it from a `NotificationListener<ScrollNotification>` when `extentAfter` falls below a threshold.
- **Remote side effects are best-effort.** Local state is the UI's source of truth (see account.md).

## Key decisions (short ADRs)

1. **No JS client (YouTube.js).** The user explicitly rejected it. Browse, search and account logic is our own Dart InnerTube code, modelled on SimpMusic's Kotlin module.
2. **NewPipeExtractor, used only for stream URLs.** InnerTube `/player` URLs are capped at about 1 MB without a PO token. SimpMusic has the same problem and also delegates to a NewPipe extractor. See streaming.md.
3. **Flutter, Android first.** iOS and desktop are out of scope for now. The Kotlin channels are Android-only.
4. **Exact YouTube Music look, different branding.** See ui.md.
