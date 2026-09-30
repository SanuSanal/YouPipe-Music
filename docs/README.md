# YouPipe Music docs

YouPipe Music is an ad-free YouTube Music client for Android, built with Flutter. It copies the YouTube Music (YTM) Android app's UI and uses its own logo. Browse, search and account features call YouTube's internal **InnerTube** API directly from Dart. Playable audio URLs come from **NewPipeExtractor**, which runs on the Android side.

These docs record the architecture and the decisions a new session needs in order to keep the code consistent. Read the index, then the modules for the area you're working on.

| Doc | Read when you touch |
|---|---|
| [architecture.md](architecture.md) | anything: layers, wiring, folder map, conventions |
| [innertube.md](innertube.md) | `lib/innertube/**`: endpoints, parsers, fixtures |
| [streaming.md](streaming.md) | stream URLs, downloads, the Kotlin channels, NewPipeExtractor |
| [playback.md](playback.md) | `lib/player/**`: queue, radio, sleep timer, effects, SponsorBlock, Android Auto |
| [ui.md](ui.md) | screens, widgets, theme, navigation, player panel, branding |
| [data.md](data.md) | drift database, migrations, library, settings storage |
| [account.md](account.md) | Google sign-in, authenticated requests, account sync |
| [testing.md](testing.md) | tests, fixtures, running on a device |
| [release.md](release.md) | the release workflow, signing, R8 keep rules, `android/app/build.gradle.kts` |
| [lockscreen.md](lockscreen.md) | the opt-in lock screen player: `LockScreenActivity.kt`, `LockScreenLauncher.kt` |
| [updates.md](updates.md) | the in-app updater: GitHub check, download, install, `UpdateChannel.kt` |
| [site.md](site.md) | the website in `site/` and its GitHub Pages workflow |
| [roadmap.md](roadmap.md) | what's done, what's next, known issues |

Docs describe the **current** state. When code changes a documented behaviour, update the doc in the same change (see `/AGENTS.md`).
