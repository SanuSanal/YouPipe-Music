# In-app updates

The app updates itself from GitHub Releases (the app isn't on the Play Store). The release side is in [release.md](release.md).

## Flow

1. **Launch check:** `AppShell.initState` waits 3 s, then calls `UpdateController.checkOnLaunch()` (`lib/providers.dart`). It first deletes old downloads, then skips the check when:
   - it's a debug build (`kDebugMode`: pubspec's `1.0.0` would never see an update, and the debug key can't install a release);
   - the `autoUpdateCheck` setting is off;
   - the release is the `skippedUpdateVersion`.
   Errors are silent.
2. **Check:** `Updater.check()` (`lib/data/updater.dart`) GETs `api.github.com/repos/SanuSanal/YouPipe-Music/releases/latest`, which leaves out drafts and prereleases.
   - There's an update when the tag's `MAJOR.MINOR.PATCH` is higher than the installed `versionName`.
   - The APK is chosen by `pickApk`: the first of `Build.SUPPORTED_ABIS` with an asset ending `-<abi>.apk`.
   - Unauthenticated API calls are limited to 60 per hour per IP, which is plenty for one call per launch.
3. **Ask first:** `showUpdateSheet` (`lib/features/update/update_sheet.dart`) shows the version, size and cleaned-up notes (`cleanReleaseNotes`), with Skip this version / Later / Update.
4. **Download:** `dio` downloads to `<temp>/updates/`. The APK is then checked against `SHA256SUMS.txt` (if the release has one). The download runs in `UpdateController`, so closing the sheet doesn't stop it; Settings → "Check for updates" shows progress and reopens the sheet.
5. **Install:** `UpdateChannel.kt` writes the APK into a `PackageInstaller` session and commits it. On `STATUS_PENDING_USER_ACTION` it starts the system confirmation screen.
   - The first time, Android asks the user to turn on "Allow from this source". The system handles that; the app doesn't need to.
   - On success the app process is replaced.

## Channel `youpipe/updater` (`UpdateChannel.kt`)

| Method | Returns |
|---|---|
| `appInfo` | `versionName`, `versionCode`, `abis` |
| `install {path}` | completes on success; errors `CANCELLED`, `SIGNATURE_MISMATCH`, `DOWNGRADE`, `INSTALL_FAILED` |
| `openUrl {url}` | opens a link in the browser |

- It needs `REQUEST_INSTALL_PACKAGES` in the manifest.
- **The status receiver is registered before `commit`**, so the result broadcast can't arrive first.
- `SIGNATURE_MISMATCH` is Android's `INSTALL_FAILED_UPDATE_INCOMPATIBLE`: the installed app was signed with a different key, such as a debug build or another person's build. The sheet then tells the user to reinstall from GitHub, because there's no in-place fix.

## Contract with the release workflow

Changing any of these breaks updates for everyone already installed:

- The tag is `vMAJOR.MINOR.PATCH`, and CI passes it as `--build-name`.
- The APK assets are named `…-<abi>.apk` with Android ABI names (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
- `SHA256SUMS.txt` is in `sha256sum` format and lists each APK by its asset name.
- Every release is signed with the same key.

## Testing

- **Unit tests:** `test/updater_test.dart` covers version comparison, ABI choice, `SHA256SUMS` parsing and notes cleanup, against `test/fixtures/github_release.json` (the trimmed v0.0.3 release).
- **On a device:** build a lower version so there's something to update to. `kDebugMode` skips the launch check, so use a release build:
  ```bash
  flutter build apk --release --build-name=0.0.1 --build-number=1
  ```
  - **Signed with the debug key**, it exercises check, download and hash, then fails with `SIGNATURE_MISMATCH`.
  - **Signed with the release key** (`android/key.properties`), it updates for real.
