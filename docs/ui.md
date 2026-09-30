# UI

## Product rule: look exactly like YouTube Music, but with YouPipe branding

- Screens, layouts, interactions and wording follow the **YouTube Music Android app**. When in doubt, match YTM.
- **App name:** "YouPipe Music" inside the app (wordmark, About). The system-facing name is the short **"YP Music"**: `android:label` in the manifest (launcher, app drawer, app info, Android Auto) and `MaterialApp.title` (recents). `applicationId`/namespace is `com.youpipe.music`.
- **Logo:** YTM's red circle with a white ring, but with a **white cylinder (pipe) in 3/4 view** in place of the play triangle. Sources are in `assets/branding/*.svg`:
  - `logo.svg`: the badge.
  - `logo_foreground.svg`: the adaptive-icon foreground, scaled into the safe zone.
  - `logo_monochrome.svg`: the Android 13 themed icon (bore cut out).
  - The notification icon is `res/drawable/ic_stat_youpipe.xml`.
- **Regenerating icons:** render the PNGs with ImageMagick (`magick -background none -density 384 x.svg -resize 1024x1024 x_1024.png`), then run `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`. Both are configured in `pubspec.yaml`.
- **One exception:** the opt-in lock screen player ([lockscreen.md](lockscreen.md)). YTM has no custom lock screen.
- **Never ship** YouTube's logos, the play-triangle mark or the YouTube Sans font. Use Roboto and Material icons.

## Theme (`lib/ui/theme/ytm_theme.dart`)

- **Dark only.**
- `YtmColors`:
  - Background `#030303`, surface `#212121`, elevated `#2A2A2A`, nav bar `#0F0F0F`.
  - Text white and `#AAAAAA`; brand red `#FF0000`.
  - Chips are 10% white, or white with black text when selected.
- `YtmSizes`: page padding 16, carousel card 160, list thumbnail 48, mini player 64, nav bar 64.
- **Toasts** are dark floating cards: `elevated` background, white text, 8dp radius (`snackBarTheme`).
- **Use the tokens.** Don't hard-code new colours.

## Navigation (`lib/ui/router.dart`, `lib/ui/navigation.dart`)

- **Bottom-nav branches:** go_router `StatefulShellRoute.indexedStack` with branches `/home`, `/explore` and `/library`.
- **Detail routes** (search, album/:id, artist/:id, playlist/:id, local/:id, list/:kind, browse) are registered **under every branch**. Pages are pushed inside the current tab, so the bottom nav and mini player stay visible, as in YTM.
- Always navigate through the helpers in `navigation.dart`:
  - `openItem`, `openAlbum`, `openArtist`, `openPlaylist`, `openBrowse`, `openSearch`… compute the branch prefix and collapse the player first.
  - `openItem` decides what a tap does: a song plays with radio, a radio playlist plays, and everything else opens its page.
- `/settings` and `/login` are root routes (full screen).
- **Tapping the current tab's icon** pops that tab back to its root.

## App shell and player panel (`lib/ui/shell/app_shell.dart`)

- **The panel:** content sits above the mini player and nav bar. One `AnimationController` (0 = mini, 1 = full) drives the panel's height; the nav bar slides out as it expands.
- **Gestures:** dragging and flinging settle the panel. `playerPanelProvider` lets any screen expand or collapse it.
- **Back button order:**
  1. An open sheet or dialog closes (`ModalRoute.of(context)?.isCurrent == false` check).
  2. The expanded player collapses (`BackButtonListener`).
  3. Pages pop.
  4. Leaving a non-Home tab goes to Home, then the app exits.
- **Toasts:** always use `showSnack` (`item_menu.dart`). Inside the shell it sets the toast's bottom margin so it floats above the mini player and nav bar (only above the system bar when the player is expanded). The shell shows "No video for this song" when video mode falls back; SponsorBlock skips are silent.

## Shared widgets (`lib/ui/widgets/`)

| Widget | Use |
|---|---|
| `YtImage` | Artwork. Resizes googleusercontent URLs (`=wN-hN`), supports local files (paths starting with `/`) and circles for artists |
| `ResponsiveListTile` | YTM row: thumbnail or track number, title, subtitle, explicit and downloaded badges, ⋮ menu, "now playing" overlay |
| `TwoRowCard` | Carousel/grid card; `width` is the whole card; videos are 16:9 |
| `SectionView` | Draws any `Section`: card carousel, Quick picks grid (`itemsPerColumn`), list shelf, mood grid |
| `SectionHeader` / `MorePill` | Strapline, title and the "More" pill |
| `showItemMenu` | The long-press/⋮ sheet (`inPlayer` adds Sleep timer, Speed and Equalizer) |
| `showSaveToPlaylist` | Local playlists, plus the account's YouTube playlists when signed in |
| `CollectionHeader`, `TintedPage`, `ArtworkTint` | Album/playlist header and page: artwork-tinted gradient, the top bar turns solid and shows the title after scrolling |
| `LoadingView`, `ErrorView`, `EmptyView`, `songCount()` | Standard states and pluralisation |

- **Full player** (`features/player/`): artwork-tinted gradient, Song/Video toggle (Video plays the music video in place of the artwork; it's dimmed when the song has no video or while casting; see playback.md), left-aligned Like/Save/Share/Album pills, seek bar and controls. The **UP NEXT / LYRICS / RELATED** sheet supports drag-to-reorder and swipe-to-remove in Up next.
- **Full-screen video** (`video_fullscreen.dart`, `openVideoFullscreen`): tapping the video in video mode shows a full-screen button for 3 s (it also shows when a video starts). Full screen is a route on the root navigator, forced to landscape with immersive system UI. Tapping shows the title, previous/play/next, the shared `SeekBar` and an exit button; they fade after 3 s while playing. Back, the collapse arrow or the exit button leave it (orientation goes back to the system default, UI mode to edge-to-edge). It closes itself when video mode ends (casting, no video).
- **Artist page:** `SliverAppBar` with `FlexibleSpaceBar`, where the full-bleed image collapses into a solid bar with the name.
- **Search:** suggestions highlight the part you haven't typed yet; search history is shown when the field is empty; filter chips use the `SearchFilter` params.
