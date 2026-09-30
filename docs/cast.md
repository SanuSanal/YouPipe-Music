# Casting (Chromecast and DLNA)

YouPipe can play on:
- **Chromecast** devices: Chromecast, Google TV, Nest speakers, TVs with Chromecast built-in. It uses the official **Google Cast SDK** with Google's **Default Media Receiver**, so there's no receiver app to register. This needs Google Play services.
- **DLNA renderers:** most smart TVs (Samsung, LG, …) and many speakers and AV receivers. This is plain UPnP AV, done in Dart.

The Cast button (top bar and full player) only shows when there's a device to cast to, as in YouTube Music. It opens our own device sheet, which lists both kinds of device, instead of the system Cast dialog. That dialog only knows Chromecasts, so this is a deliberate difference from YTM. While casting, the sheet shows a volume slider (when the device allows volume control) and "Stop casting". The full player says "Playing on <device>".

**Tested so far:** DLNA on a Samsung UE43CU7020 (2023). Chromecast has **not** been tested on a real device yet: none was available.

## Why the phone relays the audio

googlevideo URLs are bound to the phone's `ip=` and to the InnerTube client (`c=`), and they need that client's User-Agent and ≤1 MB `Range` requests (streaming.md). A TV fetching them itself gets 403s: on Wi-Fi with IPv6 every device even has its own address. So **`CastProxy.kt`** serves the song over the LAN:

- It's a minimal HTTP/1.1 server on an ephemeral port. It runs only while casting.
- Each song gets a random token; `GET/HEAD /a/<token>` supports single `Range` requests and answers 200 or 206. Anything else is a 404, and only the last 4 tokens are kept.
- Responses carry `contentFeatures.dlna.org` / `transferMode.dlna.org`, which Samsung TVs want.
- **Streamed songs:**
  - The relay extracts the stream itself (`StreamExtractorChannel.getAudioStreams`), preferring **AAC/MP4** because every receiver plays it, and falling back to Opus/WebM.
  - It fetches in 1 MB chunks through `Googlevideo.kt`, the helper it shares with the downloader.
  - A 403 mid-song re-extracts once.
- **Downloaded songs** are served from the file.
- The device is given `http://<phone's Wi-Fi IPv4>:<port>/a/<token>`.
- While casting, `CastChannel` holds a Wi-Fi lock and a partial wake lock, so the relay keeps serving with the screen off.

## Pieces

| Piece | Role |
|---|---|
| `CastOptionsProvider.kt` | Default Media Receiver. The Cast SDK's own media session and notification are **off**, so audio_service's notification and the lock screen player stay the controls. |
| `CastChannel.kt` | **Chromecast:** `routes` events (from MediaRouter; an active scan runs while the app is on screen, via `MainActivity.onResume/onPause`, because the Cast SDK alone only scans passively), `selectRoute`, `load`, `play`, `pause`, `seek`, `setVolume`, `disconnect`, plus `state` / `player` events (the player event carries the loaded relay `url`). **Relay for both:** `relayStart`, `relayUrl` → `{url, contentType}`, `relayStop`. Channels: `youpipe/cast` and `youpipe/cast/events`. |
| `lib/player/dlna.dart` | `DlnaRenderer.discover()` sends SSDP M-SEARCH for `MediaRenderer:1` and reads the device descriptions (AVTransport and RenderingControl control URLs). `DlnaSession` drives a renderer over SOAP: `SetAVTransportURI` with DIDL-Lite metadata (title, artist, album, art), `Play`, `Pause`, `Seek` (REL_TIME), `Stop`, `SetVolume`. It **polls** `GetTransportInfo` + `GetPositionInfo` every second, since renderers can't push events to us. |
| `lib/player/cast.dart` | `CastController`: the combined device list (`devices`), `connect` / `disconnect`, the combined `status`, and the `RemotePlayback` the audio handler drives. Transport commands never throw. DLNA discovery runs at start, when the app resumes and when the sheet opens. |
| `castControllerProvider` / `castStatusProvider` | Watched from the app root. The controller is handed to the audio handler (`handler.cast`). |
| `ui/widgets/cast_button.dart` | `CastButton`, `CastingLabel`, `showCastSheet`. |

## Playback while casting (`YouPipeAudioHandler`)

- **The queue stays in the handler.** `_loadIndex` loads **one song at a time** on the device (`cast.load`), with the downloaded file if there is one.
- **Transport:** `play`, `pause` and `seek` go to the device. Next and previous stay ours.
- **Following the device:**
  - Status updates are matched by relay `url`, so an update about the previous song is ignored.
  - `playbackState` is built from them, so the notification, the lock screen player and the foreground service carry on.
- **Completion:**
  - Chromecast reports idle with reason `finished`.
  - For DLNA, the song counts as finished when the renderer goes `STOPPED` right after playing within 5 s of the end. Stopping earlier on the TV counts as `canceled`.
  - Either way, the usual `_onCompleted` runs (repeat, next, radio top-up).
- **Handoff:**
  - When a device connects, the local player pauses and the song continues on the device from the same position (playing only if it was playing).
  - When casting stops, the phone is left **paused** at the device's last position, as YTM does.
- **Position:** `positionStream`, `position` and `duration` follow the device. `positionProvider` watches `castStatusProvider` to re-subscribe. SponsorBlock skipping works on the remote position.
- **Volume:**
  - When the device allows volume control (`CastStatus.volumeControl`; for DLNA this is probed on connect by setting the current volume), the handler publishes `RemoteAndroidPlaybackInfo` (20 steps), so the phone's volume keys and the system volume panel drive the device.
  - Otherwise the keys stay on the phone and the sheet hides the slider.
- **Phone-only:** the equalizer, loudness boost and speed don't apply on the device. The sleep timer pauses the device without the fade.

## Known limits

- **Samsung TVs over DLNA refuse `Seek`** (error 501 for every unit, even though they list it), so a DLNA song starts from the beginning on handoff and can't be scrubbed.
- On the tested Samsung, `SetVolume` is accepted from the phone but doesn't change the TV's volume.
- Amazon **Fire TV** has neither Google Cast nor a DLNA renderer out of the box, so it isn't listed.
- **The YouTube app seeing a TV proves nothing:** YouTube also uses DIAL, which many TVs support without Google Cast or DLNA. To check a network from a PC, send SSDP M-SEARCH (`MediaRenderer:1`) and mDNS `_googlecast._tcp.local` queries.

## Testing

- `test/cast_test.dart` covers event parsing, the state mapping and DLNA time formats.
- Verified on the device with the Samsung TV:
  - the TV is discovered and listed in the sheet;
  - connecting hands the song over;
  - pause, resume and next work;
  - the song plays past the 1 MB mark through the relay;
  - "Stop casting" stops the TV and leaves the phone paused at its position.
