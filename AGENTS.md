# AGENTS.md

YouPipe Music: a Flutter (Android) YouTube Music client. It copies the YTM UI and uses our own branding. Browse, search and account go through a pure-Dart InnerTube client; audio streams come from NewPipeExtractor.

## Before planning or changing code

1. Read `docs/README.md`, then the doc for every area your task touches (the table there maps areas to docs). At minimum, read `docs/architecture.md`.
2. Respect the decisions recorded in the docs. Don't reverse one silently. If a task needs to change one, say so to the user and update the doc.

Decisions that are easy to break by accident:

- **No YouTube.js or other JS client.** Browse, search and account stay in `lib/innertube/` (pure Dart).
- **Stream URLs come from NewPipeExtractor** through the Kotlin channel. Don't switch back to InnerTube `/player` URLs: without a PO token they stop at about 1 MB.
- **Downloads run natively** (`DownloadChannel.kt`). Stream URLs are bound to the phone's IP and to the InnerTube client that produced them.
- **The UI must match YouTube Music Android**, with YouPipe branding (the cylinder logo). Never ship YouTube logos or YouTube Sans.
- **Local library first; account sync is best-effort** (`AccountActions`).

## After making changes

- **Update the docs in the same change** when you alter architecture, a decision, an endpoint or parser behaviour, the schema, the settings keys, the navigation or player behaviour, or the status in `docs/roadmap.md`. Only record what a future session would need; not every small choice. Any added, removed or changed network call or platform channel also goes in `docs/apis.md`.
- **Keep docs modular:** edit the relevant `docs/*.md`, and add a new module (linked from `docs/README.md`) rather than growing one file without limit.
- **A schema change** needs a `schemaVersion` bump, an `onUpgrade` step, and `dart run build_runner build --delete-conflicting-outputs`.

## Working rules

- **Verification:** `flutter analyze` must report no issues. Run `flutter test`, and run `flutter test --tags live --run-skipped` when InnerTube code changes. Format with `dart format -l 120`.
- **On the device:** use the SDK adb (`%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe`), not the "Minimal ADB" on PATH. See `docs/testing.md`.
- **Secrets and personal data:**
  - Never commit cookies, signed-in responses or personal data.
  - Never type Google credentials; the user signs in themselves.
  - When testing on the user's account, keep changes minimal and undo them.
- **Git:** commit only when asked. End commit messages with the attribution line the environment provides.
