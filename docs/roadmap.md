# Status and roadmap

## Done

- **Phase 0:** proof of concept. Search and background playback work, and the NewPipeExtractor decision was made and tested (20 songs played past the 1 MB cap).
- **Phase 1, the YouTube Music clone:**
  - Branding and theme.
  - Home (chips, Quick picks, continuations), Explore (new releases, charts, moods), Search (suggestions, filters, top result).
  - Album, artist and playlist pages.
  - The expanding player with Up next, Lyrics and Related.
  - Local library, settings.
- **Phase 2:**
  - Synced lyrics (LRCLIB), sleep timer, playback speed, equalizer and loudness.
  - SponsorBlock.
  - Offline downloads.
  - Android Auto browsing.
  - Google sign-in with account library and like/save/subscribe sync, plus "Save to library".
- **Lock screen player** (opt-in, Resso-style; see [lockscreen.md](lockscreen.md)).
- **Video mode:** the Song/Video toggle plays the song's music video, in HD up to 1080p through a local DASH manifest, with a Video quality setting and a 360p fallback (see [playback.md](playback.md)).
- **Audio quality:** Low/Normal/High, DRC ("stable volume") copies skipped; the next song is preloaded for gapless playback.
- **Casting** to DLNA TVs/speakers and Chromecast, with the phone relaying the audio (see [cast.md](cast.md)). DLNA is tested on a Samsung TV; Chromecast isn't tested on a real device yet.
- **Releases:** signed APKs are published to GitHub Releases by a tag-triggered workflow (see [release.md](release.md)), and the app updates itself from them (see [updates.md](updates.md)).

## Next (not started)

- **Return YouTube Dislike** (dislike counts).
- **Remote client config** (JSON hosted on GitHub) so client version or player fixes can ship without an app release.
- **Video mode:** song↔video position alignment.
- **Discord status, home-screen widget, backup import/export, localisation, tablet layout.**
- **Lyrics translation.**

## Known issues and gaps

- **Two liked lists when signed in:** the local "Liked music" and the account's "Liked Music" (LM) overlap. They could be merged.
- **The Library "Recent activity" sort** doesn't do anything yet.
- **Android Auto:** playback and the launcher entry work on a real car (sideloaded builds need Unknown sources, see playback.md). Browsing the tree and voice or keyboard search in the car are still unchecked.
- **Downloads stop** if the app process dies, because there's no WorkManager.
- **Unavailable songs:**
  - **While casting,** an unavailable song still fails on the receiver: `CastProxy` resolves the audio natively, without the music-video fallback.
  - **Up next** doesn't grey out songs known to be unplayable.
- **Account actions not yet exercised with the real account:** adding to a YouTube playlist, saving an album or playlist, subscribing.
- **Private API:** the app uses YouTube's private API, which is against YouTube's ToS. Distribute outside the Play Store (GitHub/F-Droid).
