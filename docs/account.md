# Google account (sign-in and sync)

## Sign-in flow

1. `LoginScreen` (`/login`) opens Google's own `ServiceLogin` page (`ltmpl=music`, which continues to music.youtube.com) in `webview_flutter`. **The user types their own credentials. An agent must never enter credentials for them.**
2. When a page finishes loading on `https://music.youtube.com`, `AuthController.completeSignIn()` reads the WebView cookie jar through the Kotlin `youpipe/cookies` channel (`CookieManager.getCookie`). The auth cookies (SID, HSID…) are HttpOnly, so JavaScript can't read them.
3. If the cookie has `SAPISID` or `__Secure-3PAPISID`, it is saved to secure storage (`ytm_cookie`), set on `InnerTube.cookie`, and the account info is fetched.
4. `authProvider` restores the cookie at startup. Home and Explore wait for it.
5. **Sign out** deletes the stored cookie, clears `InnerTube.cookie`, and removes all WebView cookies.

## Authenticated requests (`lib/innertube/auth.dart`)

- Headers: `Cookie`, `Authorization: SAPISIDHASH <ts>_<sha1("<ts> <SAPISID> https://music.youtube.com")>`, `X-Goog-AuthUser: 0`, `X-Origin`.
- **The timestamp is in seconds.** SimpMusic divides by 1000 again, which looks like a bug; don't copy it. `test/auth_test.dart` pins the hash to a value computed independently.

## Sync rules (`AccountActions` in `lib/data/account.dart`)

- **Local first, remote best-effort:** write to the local library, then call InnerTube if signed in. Remote failures are logged, not shown, and a success invalidates `accountLibraryProvider`.
- **What maps to what:**
  - Song like → `like/like` / `like/removelike`.
  - Album save → `savePlaylist(album.playlistId)`.
  - Playlist save → `savePlaylist(id)`.
  - Artist subscribe → `subscription/*` with `ArtistPage.channelId`. It can differ from the artist browseId, which is only a fallback.
- "Save to / Remove from library" for songs sends feedback tokens parsed from row menus (`setInLibrary`).
- **Library screen:** local items plus `accountLibraryProvider(LibraryPage.*)`, de-duplicated by id with local winning. Pull to refresh reloads the account data.

## YouTube Music behaviours to remember

- **Liking a song also adds it (and its artist) to the account library.** Unliking does *not* remove it; that needs the separate "Remove from library" feedback token. The library list can lag behind the per-item state.
- `LM` (Liked Music) only appears in the account's playlists once the account has likes. `SE` (Episodes for Later) is hidden.
- **Save to playlist** only offers account playlists other than LM, SE and radios. Adding to a playlist the user doesn't own fails and shows a toast.

## Verified (2026-09-29, the user's real account)

- Verified: sign-in, account info, personalised Home, and like/unlike syncing to Liked Music.
- **Not yet exercised with the account:** adding to a YouTube playlist, saving an album or playlist, subscribing.
- **When testing on the user's account,** make the smallest change possible and undo it afterwards.
