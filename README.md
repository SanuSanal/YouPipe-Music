# YouPipe Music

An ad-free YouTube Music client for Android, built with Flutter. The UI follows the YouTube Music app.

## How it works

- **Browse, search, radio, lyrics:** `lib/innertube/` is a pure-Dart client for YouTube Music's internal InnerTube API (`WEB_REMIX`).
- **Audio streams:** resolved on Android by [NewPipeExtractor](https://github.com/TeamNewPipe/NewPipeExtractor) through the `youpipe/stream_extractor` method channel (`android/app/src/main/kotlin/com/youpipe/music/StreamExtractorChannel.kt`). NewPipeExtractor takes care of signature deciphering and YouTube's PO-token restrictions.
- **Playback:** `just_audio` behind `audio_service`, which provides background playback, the notification and lockscreen controls.
- **Library:** liked songs, history, saved items and your own playlists live in a local SQLite database (`drift`).

## Layout

```
lib/innertube/   InnerTube client, models, parsers
lib/data/        stream resolver, drift database, library repository
lib/player/      audio handler (queue, radio, shuffle/repeat)
lib/features/    screens (home, explore, search, album, artist, playlist, library, player, settings)
lib/ui/          theme, router, shell, shared widgets
test/innertube/  parser tests against recorded fixtures + live API smoke tests
```

## Development

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift code
flutter test                                              # parser tests (offline)
flutter test --tags live --run-skipped                    # hits the real API
flutter run
```

If YouTube changes break browsing, re-record fixtures and refresh the client version in `lib/innertube/clients.dart`. If playback breaks, bump the NewPipeExtractor version in `android/app/build.gradle.kts` first.

This project uses YouTube's private API, which is against YouTube's Terms of Service. It is meant for personal use and distribution outside the Play Store.
