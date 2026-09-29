import '../json_nav.dart';
import '../models.dart';

const _separator = ' • ';
const _typeLabels = {
  'Song',
  'Video',
  'Album',
  'Single',
  'EP',
  'Artist',
  'Playlist',
  'Episode',
  'Podcast',
  'Profile',
  'Station',
};
final _statsPattern = RegExp(
  r'(views?|plays?|subscribers?|monthly audience|monthly listeners|songs?|tracks?|episodes?|likes?)$',
  caseSensitive: false,
);
final _yearPattern = RegExp(r'^\d{4}$');

// ---------------------------------------------------------------------------------------------
// Small shared pieces
// ---------------------------------------------------------------------------------------------

List<Thumbnail> parseThumbnails(Object? container) {
  final list =
      nav<List>(container, ['musicThumbnailRenderer', 'thumbnail', 'thumbnails']) ??
      nav<List>(container, ['croppedSquareThumbnailRenderer', 'thumbnail', 'thumbnails']) ??
      nav<List>(container, ['thumbnail', 'thumbnails']) ??
      nav<List>(container, ['thumbnails']) ??
      const [];
  return list
      .whereType<Json>()
      .where((t) => t['url'] is String)
      .map((t) => Thumbnail(url: t['url'] as String, width: t['width'] as int?, height: t['height'] as int?))
      .toList();
}

BrowseEndpoint? parseBrowseEndpoint(Object? endpointHolder) {
  final be = nav<Json>(endpointHolder, ['browseEndpoint']);
  final id = be?['browseId'];
  return id is String ? BrowseEndpoint(id, params: be!['params'] as String?) : null;
}

WatchEndpoint? parseWatchEndpoint(Object? endpointHolder) {
  final we = nav<Json>(endpointHolder, ['watchEndpoint']) ?? nav<Json>(endpointHolder, ['watchPlaylistEndpoint']);
  if (we == null) return null;
  return WatchEndpoint(
    videoId: we['videoId'] as String?,
    playlistId: we['playlistId'] as String?,
    params: we['params'] as String?,
    index: we['index'] as int?,
  );
}

String? pageTypeOf(Object? endpointHolder) => nav<String>(endpointHolder, [
  'browseEndpoint',
  'browseEndpointContextSupportedConfigs',
  'browseEndpointContextMusicConfig',
  'pageType',
]);

String? _musicVideoType(Object? endpointHolder) => nav<String>(endpointHolder, [
  'watchEndpoint',
  'watchEndpointMusicSupportedConfigs',
  'watchEndpointMusicConfig',
  'musicVideoType',
]);

bool _isExplicit(Json renderer) => navList(renderer, ['subtitleBadges'])
    .followedBy(navList(renderer, ['badges']))
    .any((b) => nav<String>(b, ['musicInlineBadgeRenderer', 'icon', 'iconType']) == 'MUSIC_EXPLICIT_BADGE');

String stripPlaylistPrefix(String browseId) => browseId.startsWith('VL') ? browseId.substring(2) : browseId;

// ---------------------------------------------------------------------------------------------
// Subtitle runs: "Song • Artist & Artist • Album • 3:49"
// ---------------------------------------------------------------------------------------------

class SubtitleInfo {
  String? typeLabel;
  final artists = <ArtistRef>[];
  AlbumRef? album;
  String? year;
  Duration? duration;
  final stats = <String>[];
  final plain = <String>[];
  String text = '';
}

SubtitleInfo parseSubtitle(List<Json> runs) {
  final info = SubtitleInfo()..text = runs.map((r) => r['text'] ?? '').join();
  final groups = <List<Json>>[[]];
  for (final r in runs) {
    if (r['text'] == _separator) {
      groups.add([]);
    } else {
      groups.last.add(r);
    }
  }
  var first = true;
  for (final group in groups.where((g) => g.isNotEmpty)) {
    final text = group.map((r) => r['text'] ?? '').join().trim();
    final album = group.where((r) => pageTypeOf(r['navigationEndpoint']) == 'MUSIC_PAGE_TYPE_ALBUM').firstOrNull;
    final artistRuns = group.where((r) {
      final t = pageTypeOf(r['navigationEndpoint']);
      return t == 'MUSIC_PAGE_TYPE_ARTIST' || t == 'MUSIC_PAGE_TYPE_USER_CHANNEL';
    }).toList();

    if (album != null) {
      info.album = AlbumRef(
        name: album['text'] as String,
        id: parseBrowseEndpoint(album['navigationEndpoint'])!.browseId,
      );
    } else if (artistRuns.isNotEmpty) {
      info.artists.addAll(
        artistRuns.map(
          (r) => ArtistRef(name: r['text'] as String, id: parseBrowseEndpoint(r['navigationEndpoint'])?.browseId),
        ),
      );
    } else if (first && _typeLabels.contains(text)) {
      info.typeLabel = text;
    } else if (_yearPattern.hasMatch(text)) {
      info.year = text;
    } else if (parseDuration(text) != null) {
      info.duration = parseDuration(text);
    } else if (_statsPattern.hasMatch(text)) {
      info.stats.add(text);
    } else if (text.isNotEmpty) {
      info.plain.add(text);
    }
    first = false;
  }
  // Artists without channel links come as plain text.
  if (info.artists.isEmpty && info.plain.isNotEmpty) {
    info.artists.add(ArtistRef(name: info.plain.first));
  }
  return info;
}

// ---------------------------------------------------------------------------------------------
// Items
// ---------------------------------------------------------------------------------------------

/// Builds an item from what a row/card links to plus its parsed title and subtitle.
YTItem? itemFromParts({
  required Object? endpoint,
  required String title,
  required SubtitleInfo sub,
  required List<Thumbnail> thumbnails,
  required bool explicit,
  String? videoId,
  String? setVideoId,
  String? playlistId,
}) {
  final browse = parseBrowseEndpoint(endpoint);
  final pageType = pageTypeOf(endpoint);
  final subtitle = sub.text;

  if (videoId != null || nav<Json>(endpoint, ['watchEndpoint', 'videoId']) != null) {
    final type = _musicVideoType(endpoint);
    return SongItem(
      videoId: videoId ?? nav<String>(endpoint, ['watchEndpoint', 'videoId'])!,
      title: title,
      artists: sub.artists,
      album: sub.album,
      duration: sub.duration,
      thumbnails: thumbnails,
      isVideo: sub.typeLabel == 'Video' || (type != null && type != 'MUSIC_VIDEO_TYPE_ATV'),
      explicit: explicit,
      subtitle: subtitle,
      setVideoId: setVideoId,
    );
  }

  final watchPlaylist = nav<Json>(endpoint, ['watchPlaylistEndpoint']);
  if (watchPlaylist != null) {
    return PlaylistItem(
      id: watchPlaylist['playlistId'] as String,
      title: title,
      thumbnails: thumbnails,
      subtitle: subtitle,
      isRadio: true,
    );
  }

  if (browse == null) return null;
  switch (pageType) {
    case 'MUSIC_PAGE_TYPE_ALBUM' || 'MUSIC_PAGE_TYPE_AUDIOBOOK':
      return AlbumItem(
        browseId: browse.browseId,
        playlistId: playlistId,
        title: title,
        artists: sub.artists,
        year: sub.year,
        thumbnails: thumbnails,
        typeLabel: sub.typeLabel,
        explicit: explicit,
        subtitle: subtitle,
      );
    case 'MUSIC_PAGE_TYPE_ARTIST' || 'MUSIC_PAGE_TYPE_LIBRARY_ARTIST':
      return ArtistItem(browseId: browse.browseId, title: title, thumbnails: thumbnails, subtitle: subtitle);
    case 'MUSIC_PAGE_TYPE_PLAYLIST':
      return PlaylistItem(
        id: stripPlaylistPrefix(browse.browseId),
        title: title,
        author: sub.artists.firstOrNull,
        thumbnails: thumbnails,
        subtitle: subtitle,
        songCountText: sub.stats.where((s) => s.contains('song')).firstOrNull,
      );
    default:
      // Podcasts, episodes and profiles aren't supported.
      return null;
  }
}

/// `musicTwoRowItemRenderer`: the square/circle cards in carousels and grids.
YTItem? parseTwoRowItem(Json r) {
  final titleRuns = runsOf(r['title']);
  final title = textOf(r['title']) ?? '';
  final endpoint = r['navigationEndpoint'] ?? titleRuns.firstOrNull?['navigationEndpoint'];
  final playlistId = nav<String>(r, [
    'thumbnailOverlay',
    'musicItemThumbnailOverlayRenderer',
    'content',
    'musicPlayButtonRenderer',
    'playNavigationEndpoint',
    'watchPlaylistEndpoint',
    'playlistId',
  ]);
  return itemFromParts(
    endpoint: endpoint,
    title: title,
    sub: parseSubtitle(runsOf(r['subtitle'])),
    thumbnails: parseThumbnails(r['thumbnailRenderer']),
    explicit: _isExplicit(r),
    playlistId: playlistId,
  );
}

/// The "Save to library" toggle in a row's menu: (addToken, removeToken, inLibrary).
/// Signed out, the add action is a sign-in modal, so only the remove token is a real token.
(String?, String?, bool) libraryTokens(Json renderer) {
  for (final item in navList(renderer, ['menu', 'menuRenderer', 'items'])) {
    final t = item['toggleMenuServiceItemRenderer'];
    if (t is! Json) continue;
    final icon = nav<String>(t, ['defaultIcon', 'iconType']);
    final saved = icon == 'BOOKMARK' || icon == 'LIBRARY_SAVED' || icon == 'LIBRARY_REMOVE';
    if (!saved && icon != 'BOOKMARK_BORDER' && icon != 'LIBRARY_ADD') continue;
    final def = nav<String>(t, ['defaultServiceEndpoint', 'feedbackEndpoint', 'feedbackToken']);
    final tog = nav<String>(t, ['toggledServiceEndpoint', 'feedbackEndpoint', 'feedbackToken']);
    return saved ? (tog, def, true) : (def, tog, false);
  }
  return (null, null, false);
}

/// `musicResponsiveListItemRenderer`: the rows in search results, playlists, albums and shelves.
YTItem? parseResponsiveListItem(Json r) {
  final flex = navList(r, [
    'flexColumns',
  ]).map((c) => c['musicResponsiveListItemFlexColumnRenderer']).whereType<Json>().toList();
  if (flex.isEmpty) return null;

  final titleRuns = runsOf(flex[0]['text']);
  final title = textOf(flex[0]['text']) ?? '';
  // Row subtitle can be spread over several columns (artist | album); join them as groups.
  final subRuns = <Json>[
    for (final (i, col) in flex.skip(1).indexed) ...[
      if (i > 0 && runsOf(col['text']).isNotEmpty) {'text': _separator},
      ...runsOf(col['text']),
    ],
  ];
  final fixed = textOf(nav(r, ['fixedColumns', 0, 'musicResponsiveListItemFixedColumnRenderer', 'text']));
  if (fixed != null && parseDuration(fixed) != null) {
    subRuns.addAll([
      {'text': _separator},
      {'text': fixed},
    ]);
  }

  final playEndpoint = nav<Json>(r, [
    'overlay',
    'musicItemThumbnailOverlayRenderer',
    'content',
    'musicPlayButtonRenderer',
    'playNavigationEndpoint',
  ]);
  final endpoint = r['navigationEndpoint'] ?? titleRuns.firstOrNull?['navigationEndpoint'] ?? playEndpoint;
  final videoId =
      nav<String>(r, ['playlistItemData', 'videoId']) ??
      nav<String>(titleRuns.firstOrNull, ['navigationEndpoint', 'watchEndpoint', 'videoId']) ??
      (r['navigationEndpoint'] == null ? nav<String>(playEndpoint, ['watchEndpoint', 'videoId']) : null);

  final item = itemFromParts(
    endpoint: endpoint,
    title: title,
    sub: parseSubtitle(subRuns),
    thumbnails: parseThumbnails(r['thumbnail']),
    explicit: _isExplicit(r),
    videoId: videoId,
    setVideoId: nav<String>(r, ['playlistItemData', 'playlistSetVideoId']),
    playlistId: nav<String>(playEndpoint, ['watchPlaylistEndpoint', 'playlistId']),
  );
  if (item is! SongItem) return item;
  final (add, remove, inLibrary) = libraryTokens(r);
  if (add == null && remove == null) return item;
  return SongItem(
    videoId: item.videoId,
    title: item.title,
    artists: item.artists,
    album: item.album,
    duration: item.duration,
    thumbnails: item.thumbnails,
    isVideo: item.isVideo,
    explicit: item.explicit,
    subtitle: item.subtitle,
    setVideoId: item.setVideoId,
    libraryAddToken: add,
    libraryRemoveToken: remove,
    inLibrary: inLibrary,
  );
}

/// `playlistPanelVideoRenderer`: one row of the Up next queue.
SongItem? parsePlaylistPanelVideo(Json r) {
  final videoId = r['videoId'] as String?;
  if (videoId == null) return null;
  final sub = parseSubtitle(runsOf(r['longBylineText']));
  final type = _musicVideoType(r['navigationEndpoint']);
  return SongItem(
    videoId: videoId,
    title: textOf(r['title']) ?? '',
    artists: sub.artists,
    album: sub.album,
    duration: parseDuration(textOf(r['lengthText'])),
    thumbnails: parseThumbnails(r['thumbnail']),
    isVideo: type != null && type != 'MUSIC_VIDEO_TYPE_ATV',
    explicit: _isExplicit(r),
    subtitle: sub.text,
    setVideoId: r['playlistSetVideoId'] as String?,
  );
}

/// `musicNavigationButtonRenderer`: mood/genre tiles and Explore shortcuts.
MoodItem? parseNavigationButton(Json r) {
  final endpoint = parseBrowseEndpoint(r['clickCommand']);
  if (endpoint == null) return null;
  return MoodItem(
    title: textOf(r['buttonText']) ?? '',
    endpoint: endpoint,
    color: nav<int>(r, ['solid', 'leftStripeColor']),
  );
}

/// Parses any of the item renderers found inside shelves.
YTItem? parseAnyItem(Json wrapper) {
  if (wrapper['musicTwoRowItemRenderer'] case final Json r) return parseTwoRowItem(r);
  if (wrapper['musicResponsiveListItemRenderer'] case final Json r) return parseResponsiveListItem(r);
  if (wrapper['playlistPanelVideoRenderer'] case final Json r) return parsePlaylistPanelVideo(r);
  return null;
}
