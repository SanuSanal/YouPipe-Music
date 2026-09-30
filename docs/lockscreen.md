# Lock screen player

An opt-in, Resso-style lock screen: the album art fills the screen, with a clock at the top and the player controls at the bottom. It is shown over the keyguard while music plays.

**This is a deliberate exception to the "match YouTube Music" rule** (ui.md), because YouTube Music has no custom lock screen. It is **off by default**: Settings → Playback → "Lock screen player".

## Why an activity, not the media session

The system lock-screen media card is drawn by System UI from our media session (audio_service already provides the title, artist, artwork and actions). We can't restyle it, and since Android 11 System UI no longer shows full-screen album art. Apps like Resso, NetEase and QQ Music instead show **their own activity over the keyguard**. We do the same.

## Pieces

| Piece | Role |
|---|---|
| `LockScreenLauncher.kt` | Registered from `MainActivity` on the application context. On `ACTION_SCREEN_OFF` it starts `LockScreenActivity`, but only when the `flutter.lockScreenPlayer` pref is true, `Settings.canDrawOverlays` returns true, and the session is **playing**. It follows the state with its own `MediaBrowserCompat` connection to `AudioService`. It also serves the channel `youpipe/lockscreen`: `canDrawOverlays` and `requestOverlay`. |
| `LockScreenActivity.kt` | Built with plain Views (`res/layout/activity_lock_screen.xml`, `LockScreenTheme`). It is `showWhenLocked`, `singleInstance`, `noHistory` and `excludeFromRecents`, with its own task affinity. It talks only to audio_service's media session through a `MediaControllerCompat`, so it doesn't need the Flutter UI. |
| `lib/player/lock_screen.dart` | Dart side of the channel. |
| `_LockScreenTile` (settings_screen.dart) | Turning the switch on without the permission opens the system page. The setting is saved when the app resumes with the permission granted. On Android 11+ that page is the full app list: the user picks "YP Music". |

- **Why the permission:** Android 10+ blocks a background app from starting an activity. "Display over other apps" (`SYSTEM_ALERT_WINDOW`) is the exemption. Without it nothing is launched, and playback and the system media card are unaffected.
- **Artwork:** the session's `ALBUM_ART` bitmap is shown first. Then a full-resolution copy of `DISPLAY_ICON_URI` is fetched with OkHttp (googleusercontent `=wN-hN` becomes `=w1200-h1200`). Local `file:` artwork is decoded directly.
- **Controls:**
  - Play/pause, previous, next and seek use the standard transport controls.
  - **Like** and **Repeat** are session custom actions (`toggleLike` and `cycleRepeat`), handled by `YouPipeAudioHandler.customAction`.
  - Like goes through `onToggleLike`, which `lockScreenLikeProvider` sets to `AccountActions.setLiked`.
  - The liked state reaches the screen as the media item extra `liked` (a long of 1 in the metadata). It is kept current by `lockScreenLikeProvider` through `handler.setLiked`.
- **Seek bar:** `WavyProgressDrawable.kt`. The played part is a small sine wave that drifts while playing and eases flat when paused, like Android 13's media player; the rest is a faint straight line.
- **Position** is extrapolated from `PlaybackStateCompat` (position + elapsed × speed) every 500 ms.

## Security rules

- **It never unlocks by itself.** "Swipe up to unlock" (or Back) calls `KeyguardManager.requestDismissKeyguard`, so the system still asks for the PIN, pattern or biometrics. Cancelling brings the player back.
- **Nothing on the screen opens the app** or shows library or account data. It shows only the now-playing item.
- **It closes itself** on `ACTION_USER_PRESENT` (unlocked another way), and in `onResume` when the phone is awake but the keyguard isn't locked (woken before the lock delay ran out).
