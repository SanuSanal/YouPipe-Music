# InnerTube client (`lib/innertube/`)

## Client

- `InnerTube` (`innertube.dart`) POSTs JSON to `https://music.youtube.com/youtubei/v1/<endpoint>?prettyPrint=false` as the **WEB_REMIX** client (`clients.dart`). Each body carries `context.client` (`clientName`, `clientVersion`, `hl`, `gl`, `visitorData`).
- **visitorData** comes from `visitor_id` (`ensureVisitorData()`) or the first response, and is persisted in prefs (`visitorData`). Without it YouTube serves degraded, generic responses.
- `hl`/`gl` come from Settings (`SettingsController._apply`). Charts ignore `gl` and use the IP's country.
- **When YouTube starts rejecting requests,** first refresh `YouTubeClient.webRemix.clientVersion` (from `INNERTUBE_CLIENT_VERSION` in the music.youtube.com page source, or from SimpMusic's `YouTubeClient.kt`), and keep `tool/record_fixtures.py`'s `VER` in sync.
- Signed-in requests add `Cookie`, `Authorization: SAPISIDHASH …`, `X-Goog-AuthUser: 0` and `X-Origin` (see account.md).

## Endpoints in use

| Method | Endpoint / browseId | Parser |
|---|---|---|
| `home({chip})` | browse `FEmusic_home` (a chip's own browse endpoint when filtered) | `parseHome` |
| `sectionsContinuation` | browse `{continuation}` | `parseSectionListContinuation` |
| `explore()` | browse `FEmusic_explore` | `parseExplore` |
| `browseSections(ep)` | charts, new releases, moods, mood categories, every "More" button | `parseSectionsPage` |
| `search(q, filter)` / `searchContinuation` | `search` (`params` = `SearchFilter` blob) | `parseSearch` / `parseSearchContinuation` |
| `searchSuggestions` | `music/get_search_suggestions` | `parseSearchSuggestions` |
| `album(id)` | browse `MPREb_…` | `parseAlbum` |
| `artist(id)` | browse `UC…` | `parseArtist` |
| `playlist(id)` / `playlistContinuation` | browse `VL<playlistId>` | `parsePlaylist` / `parsePlaylistContinuation` |
| `next(WatchEndpoint)` / `nextContinuation` | `next` (radio = `playlistId: RDAMVM<videoId>`) | `parseNext` / `parseNextContinuation` |
| `lyrics(ep)` / `related(ep)` | browse `MPLY…` / `MPTR…` (from `next` tabs) | `parseLyrics` / `parseRelated` |
| `accountInfo()` | `account/account_menu` | `parseAccountMenu` |
| `library(LibraryPage)` | `FEmusic_liked_playlists`, `_liked_videos`, `_liked_albums`, `_library_corpus_track_artists`, `_library_corpus_artists` | `parseSectionsPage` |
| `like` / `removeLike` / `savePlaylist` | `like/like`, `like/removelike` (target `videoId` or `playlistId`) | none |
| `subscribe` | `subscription/subscribe`, `subscription/unsubscribe` (`channelIds`) | none |
| `createPlaylist` / `addToPlaylist` | `playlist/create`, `browse/edit_playlist` (`ACTION_ADD_VIDEO`) | none |
| `feedback(tokens)` | `feedback` (`feedbackTokens`: library save/remove) | none |

## Parsing approach

- `json_nav.dart`: `nav<T>(json, [path])` walks maps and lists and returns null on any miss. `navList`, `textOf` (runs or simpleText) and `parseDuration` complete the toolkit. Parsers never throw on shape changes; they skip what they don't recognise.
- `parsers/items.dart` turns renderers into `YTItem`s:
  - `musicTwoRowItemRenderer` (cards), `musicResponsiveListItemRenderer` (rows), `playlistPanelVideoRenderer` (queue rows) and `musicNavigationButtonRenderer` (mood tiles, as `MoodItem`).
  - **The item type comes from the navigation endpoint:** a `watchEndpoint` gives a `SongItem`, a `watchPlaylistEndpoint` gives a radio `PlaylistItem` (`isRadio`), and a `browseEndpoint` is typed by `pageType`: ALBUM → `AlbumItem`, ARTIST → `ArtistItem`, PLAYLIST → `PlaylistItem`. Podcasts, episodes and profiles return null (unsupported).
  - **Subtitles:** `parseSubtitle` splits runs on `" • "` into groups and classifies each group as type label, artists (runs with ARTIST/USER_CHANNEL page types), album, year, duration or stats. The row's flex columns are joined into one run list first.
  - `SongItem.isVideo` = `musicVideoType != MUSIC_VIDEO_TYPE_ATV`, or the type label is "Video".
  - The "Save to library" toggle in a row's menu yields `libraryAddToken`, `libraryRemoveToken` and `inLibrary`. Icons: `BOOKMARK_BORDER`/`LIBRARY_ADD` = not saved, `BOOKMARK`/`LIBRARY_SAVED` = saved. Signed out, the add action is a sign-in modal (null token).
- `parsers/pages.dart`: `parseSection` handles `musicCarouselShelfRenderer`, `musicImmersiveCarouselShelfRenderer`, `musicShelfRenderer` and `gridRenderer`, unwrapping `itemSectionRenderer` (library pages). `numItemsPerColumn` marks "Quick picks"-style grids.
- **Album tracks** leave out artists, album and art. `parseAlbum` fills them in from the header.

## Response quirks worth remembering

- **Continuations come in two formats,** sometimes in the same response: `continuations[0].nextContinuationData` or `nextRadioContinuationData`, or a trailing `continuationItemRenderer.continuationEndpoint.continuationCommand.token`. `continuationOf()` checks both. Continuation requests send `{"continuation": token}` in the body.
- **Unfiltered search is flat:** every result is its own `itemSectionRenderer` with a type label ("Song •", "Album •"…) and there are no category shelves. `musicCardShelfRenderer` is the top result.
- **A playlist's `sectionListRenderer` continuation** loads *related shelves*, not more songs, once the songs are exhausted. `parsePlaylistContinuation` returns either songs or sections.
- **Anonymous home** has no "Quick picks". It appears once there's listening history (personalised by `visitorData` or the account).
- **Empty library pages** return an `itemSectionRenderer` holding a `messageRenderer`, which parses to zero items and is not an error.
- **Account playlist ids:** `LM` is Liked Music and `SE` is Episodes for Later (hidden, since podcasts are unsupported).

## Music videos (video mode)

- **The anonymous `next` response no longer links a song to its music video.** As of 2026-09, the `playlistPanelVideoWrapperRenderer.counterpart` / `segmentMap` that YouTube Music once sent is missing for WEB_REMIX, ANDROID_MUSIC and IOS_MUSIC, with `isAudioOnly` true or false. It may still exist for signed-in users.
- So `InnerTube.musicVideoFor(song)` works like this:
  - a song that already is a video (`isVideo`) plays itself;
  - otherwise it runs a **Videos search** for `"<title> <first artist>"`;
  - `pickMusicVideo` (`innertube/music_video.dart`) takes the first video whose title contains the song title (brackets stripped from the inside out, e.g. `[… (TM) …]`) and that shares an artist, or names one in its title.
- It's a heuristic: it can miss, and it can pick a live or lyric video. `MusicVideoFinder` (providers.dart) caches the answer per song.
- Without a segment map, song and video positions aren't aligned. Switching keeps the same timestamp.

## Fixtures

- `test/innertube/fixtures/*.json` are real anonymous responses. `tool/record_fixtures.py test/innertube/fixtures` re-records them.
- `tool/renderer_tree.py <file>` prints a response's renderer skeleton, which is the quickest way to learn a new layout before writing a parser.
- Signed-in responses aren't recorded as fixtures. They contain personal data, so don't commit them.
