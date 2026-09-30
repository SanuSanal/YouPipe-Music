# Testing

## Automated

```bash
flutter analyze                          # must report no issues
flutter test                             # offline: parsers (fixtures), auth hash, LRC, Android Auto tree
flutter test --tags live --run-skipped   # hits the real InnerTube API (smoke test for YouTube changes)
```

| Test | Covers |
|---|---|
| `test/innertube/parsers_test.dart` | Every page parser against the recorded fixtures |
| `test/innertube/live_test.dart` | Home, chips, continuations, search, album/artist/playlist, radio, lyrics, explore against the live API. Tagged `live` and skipped by default (`dart_test.yaml`) |
| `test/auth_test.dart` | Cookie parsing and SAPISIDHASH |
| `test/lyrics_test.dart` | LRC parsing, active line, title cleaning |
| `test/stream_resolver_test.dart` | Audio stream choice for Low/Normal/High (Opus first, AAC fallback) |
| `test/audio_effects_test.dart` | The equalizer channel wrapper: a refused equalizer is reported unavailable and logged, never thrown |
| `test/auto_browser_test.dart` | The Android Auto tree, using a Dio interceptor that serves fixtures and an in-memory drift DB (`NativeDatabase.memory()`) |

- **Mocking InnerTube:** pass a `Dio` with an interceptor that resolves requests to fixture JSON (see `auto_browser_test.dart`).
- **When a live test fails,** re-record the fixtures (`python tool/record_fixtures.py test/innertube/fixtures`), inspect them with `tool/renderer_tree.py`, and fix the parser.

## On a device

- **Build and install:** `flutter build apk --debug`, then `adb install -r build/app/outputs/flutter-apk/app-debug.apk`, then launch with `adb shell am start -n com.youpipe.music/.MainActivity`.
- **Use the Android SDK's adb** (`%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe`). The dev machine also has an older "Minimal ADB" on PATH, and mixing the two knocks the phone offline.
- **Drive the UI** with `adb shell input tap/text/keyevent` and check with `adb exec-out screencap -p`. The phone is 1080×2400; the bottom nav sits at y≈2268 (Home x≈180, Explore x≈540, Library x≈900).
- **Playback state:** `adb shell dumpsys media_session`. Look at `state=3` (playing), `position`, `buffered position` and `active item id`.
- **App logs:** `adb logcat -s flutter:I`. The app's own messages start with `YouPipe:`, and error log entries show as `YouPipe: [source] …`. On the phone itself, open the Error log page by tapping the version in Settings → About three times.
- **Losing the network:** with the user's OK, `adb shell svc wifi disable` / `enable` while a song plays. Cut it early in a song, when the buffer is thin, to hit the recovery path, and always turn Wi-Fi back on.
- **Stream and download URLs are bound to the phone's IP** (often IPv6), so they can't be replayed from the PC.
- **Don't change system settings** (airplane mode etc.) on the user's phone. Check offline playback by confirming that the downloaded file exists and plays.

## Manual regression checklist

1. Search → play → background with the screen off: position keeps moving past 60 s. That's the PO-token cap; if it stops there, streams are broken.
2. Radio fills the Up next queue; auto-advance works; the notification controls work.
3. The album, artist and playlist pages load; the top bar turns solid on scroll.
4. Synced lyrics highlight lines; the equalizer preset changes the bands and the sound. The EQ still applies after swiping the app away and playing again.
5. Downloading a song finishes and it plays from the local file.
6. Back closes a sheet first, then collapses the player.
