# Releases

Releases are built and published by `.github/workflows/release.yml` when a `vMAJOR.MINOR.PATCH` tag is pushed.

## Cutting a release

```bash
git tag v1.2.3
git push origin v1.2.3
```

The workflow:

1. Checks the tag format, then runs `flutter analyze` and `flutter test`.
2. Builds split APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`) with `--build-name` taken from the tag and `--build-number` set to `github.run_number`. Nothing is committed back; `pubspec.yaml`'s version is only the local default.
3. Publishes a GitHub release for the tag with `YouPipe-Music-v1.2.3-<abi>.apk`, `SHA256SUMS.txt` and generated notes.

A failed run leaves no release. Delete and re-push the tag to retry.

## Signing

- `android/app/build.gradle.kts` signs release builds with the key given by `ANDROID_KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` and `KEY_PASSWORD` (env vars), or else by `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`; gitignored). With neither, it falls back to the debug key.
- CI reads the repo secrets `ANDROID_KEYSTORE_BASE64` (the `.jks` base64-encoded), `KEYSTORE_PASSWORD`, `KEY_ALIAS` and optionally `KEY_PASSWORD` (defaults to the store password, as PKCS12 keystores require). The workflow fails if a required secret is missing, so a release is never debug-signed.
- **Never lose or change the keystore.** Android only installs an update signed with the same key; a new key forces every user to uninstall, losing their library.
- The CI key differs from the local debug key, so switching a phone between a release and a debug build needs an uninstall.

## Shrinking (R8)

Release builds are minified, which debug builds never exercise. After changing native code or dependencies, build a release (`flutter build apk --release`) and play a song on a device before tagging.

- `android/app/proguard-rules.pro` keeps NewPipeExtractor and Rhino whole (Rhino uses reflection to run YouTube's player JS) and silences Rhino's references to desktop-JVM classes (`java.beans`, `javax.script`).
- `android/app/src/main/res/raw/keep.xml` keeps resources looked up by name, which resource shrinking can't see. Today that's `ic_stat_youpipe`, the `audio_service` notification icon; without it, the app crashes on the first play with "Invalid notification (no valid small icon)". Add any new by-name resource there.
