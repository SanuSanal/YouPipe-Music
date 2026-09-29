# Local data

## Drift database (`lib/data/db/app_database.dart`, file `youpipe`)

| Table | Purpose |
|---|---|
| `Songs` | Cache of song metadata (artists as JSON), so library views work offline. Every table that references songs upserts here first |
| `LikedSongs` | Local likes (`likedAt`) |
| `PlayHistory` | One row per play; the UI groups by song, newest first |
| `SavedAlbums`, `SavedArtists`, `SavedPlaylists` | Items saved or subscribed locally |
| `LocalPlaylists`, `LocalPlaylistItems` | Playlists made in YouPipe (ordered by `position`, cascade delete) |
| `SearchHistory` | Recent searches (the query is the primary key) |
| `Downloads` | Offline songs: `status` (queued/downloading/done/failed), file/art paths, byte counts |

- **Schema version 2.** v1 → v2 added `Downloads` (`onUpgrade: createTable`). Every schema change needs a version bump and an `onUpgrade` step, because users have existing databases.
- **Foreign keys** are enabled in `beforeOpen`.
- **After editing tables,** run `dart run build_runner build --delete-conflicting-outputs`. `app_database.g.dart` is committed.
- **Converters:** `songToCompanion` and `songFromRow` convert between rows and `SongItem`. `encodeArtists`/`decodeArtists` store artist names and ids.

## LibraryRepository (`lib/data/library_repository.dart`)

- Has reactive `watch*` streams (exposed as `StreamProvider`s in `providers.dart`) and write methods for likes, history, saved items, local playlists (create/rename/delete/add/remove/reorder) and search history.
- **Call sites that should sync to the account** use `AccountActions` (see account.md) instead of calling `setLiked`/`setSaved` directly.

## Preferences and secrets

- **SharedPreferences keys:** `visitorData`, `quality`, `hl`, `gl`, `saveHistory`, `skipNonMusic`, `eqEnabled`, `eqGains`, `loudnessDb`, `eqPreset`, `autoUpdateCheck`, `skippedUpdateVersion` (see updates.md).
- **Session cookie:** `flutter_secure_storage`, key `ytm_cookie`. Never log it or write it anywhere else.
- **Downloads** live under `<applicationSupportDirectory>/downloads/`. To inspect them on a debug build: `adb shell run-as com.youpipe.music ls files/downloads`.
