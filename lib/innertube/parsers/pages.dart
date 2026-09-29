import '../json_nav.dart';
import '../models.dart';
import 'items.dart';

// ---------------------------------------------------------------------------------------------
// Continuations: YouTube uses two formats, sometimes in the same response.
// ---------------------------------------------------------------------------------------------

String? continuationOf(Object? container, [List<Json> items = const []]) =>
    nav<String>(container, ['continuations', 0, 'nextContinuationData', 'continuation']) ??
    nav<String>(container, ['continuations', 0, 'nextRadioContinuationData', 'continuation']) ??
    nav<String>(items.lastOrNull, ['continuationItemRenderer', 'continuationEndpoint', 'continuationCommand', 'token']);

List<T> _items<T>(List<Json> wrappers, T? Function(Json) parse) => [
  for (final w in wrappers)
    if (parse(w) case final T item) item,
];

// ---------------------------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------------------------

Section? parseSection(Json wrapper) {
  final carousel = wrapper['musicCarouselShelfRenderer'] ?? wrapper['musicImmersiveCarouselShelfRenderer'];
  if (carousel is Json) {
    final header =
        nav<Json>(carousel, ['header', 'musicCarouselShelfBasicHeaderRenderer']) ??
        nav<Json>(carousel, ['header', 'musicImmersiveCarouselShelfBasicHeaderRenderer']) ??
        const {};
    final contents = navList(carousel, ['contents']);
    final perColumn = carousel['numItemsPerColumn'];
    return Section(
      title: textOf(header['title']) ?? '',
      strapline: textOf(header['strapline']),
      thumbnails: parseThumbnails(header['thumbnail']),
      items: _items(contents, parseAnyItem),
      moods: _items(
        contents,
        (w) => w['musicNavigationButtonRenderer'] is Json
            ? parseNavigationButton(w['musicNavigationButtonRenderer'] as Json)
            : null,
      ),
      moreEndpoint: parseBrowseEndpoint(nav(header, ['moreContentButton', 'buttonRenderer', 'navigationEndpoint'])),
      itemsPerColumn: perColumn is int ? perColumn : int.tryParse('${perColumn ?? ''}'),
    );
  }

  if (wrapper['musicShelfRenderer'] case final Json shelf) {
    return Section(
      title: textOf(shelf['title']) ?? '',
      items: _items(navList(shelf, ['contents']), parseAnyItem),
      moreEndpoint: parseBrowseEndpoint(shelf['bottomEndpoint']),
    );
  }

  if (wrapper['gridRenderer'] case final Json grid) {
    final items = navList(grid, ['items']);
    return Section(
      title: textOf(nav(grid, ['header', 'gridHeaderRenderer', 'title'])) ?? '',
      items: _items(items, parseAnyItem),
      moods: _items(
        items,
        (w) => w['musicNavigationButtonRenderer'] is Json
            ? parseNavigationButton(w['musicNavigationButtonRenderer'] as Json)
            : null,
      ),
    );
  }
  return null;
}

List<Section> parseSections(List<Json> wrappers) =>
    _items(wrappers, parseSection).where((s) => s.items.isNotEmpty || s.moods.isNotEmpty).toList();

Json? _singleColumnSectionList(Json data) => nav<Json>(data, [
  'contents',
  'singleColumnBrowseResultsRenderer',
  'tabs',
  0,
  'tabRenderer',
  'content',
  'sectionListRenderer',
]);

Json? _twoColumnHeaderList(Json data) => nav<Json>(data, [
  'contents',
  'twoColumnBrowseResultsRenderer',
  'tabs',
  0,
  'tabRenderer',
  'content',
  'sectionListRenderer',
]);

Json? _twoColumnSecondary(Json data) =>
    nav<Json>(data, ['contents', 'twoColumnBrowseResultsRenderer', 'secondaryContents', 'sectionListRenderer']);

// ---------------------------------------------------------------------------------------------
// Home / generic browse
// ---------------------------------------------------------------------------------------------

HomePage parseHome(Json data) {
  final list = _singleColumnSectionList(data) ?? const {};
  final chips = [
    for (final c in navList(list, ['header', 'chipCloudRenderer', 'chips']))
      if (c['chipCloudChipRenderer'] case final Json chip)
        if (parseBrowseEndpoint(chip['navigationEndpoint']) case final BrowseEndpoint endpoint)
          HomeChip(
            title: textOf(chip['text']) ?? '',
            endpoint: endpoint,
            deselectEndpoint: parseBrowseEndpoint(chip['onDeselectedCommand']),
            selected: chip['isSelected'] == true,
          ),
  ];
  return HomePage(
    chips: chips,
    sections: parseSections(navList(list, ['contents'])),
    continuation: continuationOf(list),
  );
}

/// Continuation of any section list (home, charts, playlist related shelves...).
SectionsPage parseSectionListContinuation(Json data) {
  final cont = nav<Json>(data, ['continuationContents', 'sectionListContinuation']) ?? const {};
  return SectionsPage(sections: parseSections(navList(cont, ['contents'])), continuation: continuationOf(cont));
}

/// Any browse page made of sections (charts, new releases, mood categories, "More" pages).
SectionsPage parseSectionsPage(Json data) {
  final list = _singleColumnSectionList(data) ?? _twoColumnSecondary(data) ?? const {};
  final title =
      textOf(nav(data, ['header', 'musicHeaderRenderer', 'title'])) ??
      textOf(nav(data, ['header', 'musicImmersiveHeaderRenderer', 'title'])) ??
      textOf(nav(_twoColumnHeaderList(data), ['contents', 0, 'musicResponsiveHeaderRenderer', 'title']));
  return SectionsPage(
    title: title,
    sections: parseSections(navList(list, ['contents'])),
    continuation: continuationOf(list),
  );
}

ExplorePage parseExplore(Json data) {
  final wrappers = navList(_singleColumnSectionList(data), ['contents']);
  final sections = parseSections(wrappers);
  final shortcuts = sections.where((s) => s.title.isEmpty && s.moods.isNotEmpty).expand((s) => s.moods).toList();
  return ExplorePage(shortcuts: shortcuts, sections: sections.where((s) => s.title.isNotEmpty).toList());
}

// ---------------------------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------------------------

SearchPage parseSearch(Json data) {
  final contents = navList(data, [
    'contents',
    'tabbedSearchResultsRenderer',
    'tabs',
    0,
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
  ]);
  YTItem? top;
  var topItems = const <YTItem>[];
  final items = <YTItem>[];
  String? continuation;

  for (final section in contents) {
    if (section['musicCardShelfRenderer'] case final Json card) {
      final titleRun = runsOf(card['title']).firstOrNull;
      top = itemFromParts(
        endpoint: card['onTap'] ?? titleRun?['navigationEndpoint'],
        title: textOf(card['title']) ?? '',
        sub: parseSubtitle(runsOf(card['subtitle'])),
        thumbnails: parseThumbnails(card['thumbnail']),
        explicit: false,
      );
      topItems = _items(navList(card, ['contents']), parseAnyItem);
    } else if (section['musicShelfRenderer'] case final Json shelf) {
      final rows = navList(shelf, ['contents']);
      items.addAll(_items(rows, parseAnyItem));
      continuation ??= continuationOf(shelf, rows);
    } else if (section['itemSectionRenderer'] case final Json itemSection) {
      items.addAll(_items(navList(itemSection, ['contents']), parseAnyItem));
    }
  }
  return SearchPage(topResult: top, topResultItems: topItems, items: items, continuation: continuation);
}

SearchPage parseSearchContinuation(Json data) {
  final shelf = nav<Json>(data, ['continuationContents', 'musicShelfContinuation']) ?? const {};
  final rows = navList(shelf, ['contents']);
  return SearchPage(items: _items(rows, parseAnyItem), continuation: continuationOf(shelf, rows));
}

SearchSuggestions parseSearchSuggestions(Json data) {
  final queries = <String>[];
  final items = <YTItem>[];
  for (final section in navList(data, ['contents'])) {
    for (final c in navList(section, ['searchSuggestionsSectionRenderer', 'contents'])) {
      if (c['searchSuggestionRenderer'] case final Json s) {
        final q = nav<String>(s, ['navigationEndpoint', 'searchEndpoint', 'query']) ?? textOf(s['suggestion']);
        if (q != null) queries.add(q);
      } else if (parseAnyItem(c) case final YTItem item) {
        items.add(item);
      }
    }
  }
  return SearchSuggestions(queries: queries, items: items);
}

// ---------------------------------------------------------------------------------------------
// Album / playlist / artist
// ---------------------------------------------------------------------------------------------

Json _responsiveHeader(Json data) =>
    nav<Json>(_twoColumnHeaderList(data), ['contents', 0, 'musicResponsiveHeaderRenderer']) ??
    nav<Json>(_twoColumnHeaderList(data), [
      'contents',
      0,
      'musicEditablePlaylistDetailHeaderRenderer',
      'header',
      'musicResponsiveHeaderRenderer',
    ]) ??
    const {};

String? _headerPlaylistId(Json header) {
  for (final b in navList(header, ['buttons'])) {
    final ep = nav<Json>(b, ['musicPlayButtonRenderer', 'playNavigationEndpoint']);
    final id =
        nav<String>(ep, ['watchPlaylistEndpoint', 'playlistId']) ?? nav<String>(ep, ['watchEndpoint', 'playlistId']);
    if (id != null) return id;
  }
  return null;
}

String? _description(Json header) =>
    textOf(nav(header, ['description', 'musicDescriptionShelfRenderer', 'description']));

AlbumPage parseAlbum(Json data, String browseId) {
  final header = _responsiveHeader(data);
  final sub = parseSubtitle(runsOf(header['subtitle']));
  final artists = parseSubtitle(runsOf(header['straplineTextOne'])).artists;
  final thumbnails = parseThumbnails(header['thumbnail']);
  final title = textOf(header['title']) ?? '';
  final album = AlbumItem(
    browseId: browseId,
    playlistId: _headerPlaylistId(header),
    title: title,
    artists: artists,
    year: sub.year,
    thumbnails: thumbnails,
    typeLabel: sub.typeLabel,
    subtitle: sub.text,
  );

  final secondary = navList(_twoColumnSecondary(data), ['contents']);
  final songs = <SongItem>[];
  for (final s in secondary) {
    for (final row in navList(s, ['musicShelfRenderer', 'contents'])) {
      if (parseAnyItem(row) case final SongItem song) {
        // Album rows leave out what the header already says.
        songs.add(
          song.copyWith(
            artists: song.artists.isEmpty ? artists : song.artists,
            album: AlbumRef(name: title, id: browseId),
            thumbnails: song.thumbnails.isEmpty ? thumbnails : song.thumbnails,
          ),
        );
      }
    }
  }
  return AlbumPage(
    album: album,
    songs: songs,
    description: _description(header),
    secondSubtitle: textOf(header['secondSubtitle']),
    otherSections: parseSections(secondary.where((s) => s['musicShelfRenderer'] == null).toList()),
  );
}

PlaylistPage parsePlaylist(Json data, String browseId) {
  final header = _responsiveHeader(data);
  final sub = parseSubtitle(runsOf(header['subtitle']));
  final authorName = nav<String>(header, ['facepile', 'avatarStackViewModel', 'text', 'content']);
  final strapArtists = parseSubtitle(runsOf(header['straplineTextOne'])).artists;
  final playlist = PlaylistItem(
    id: stripPlaylistPrefix(browseId),
    title: textOf(header['title']) ?? '',
    author: strapArtists.firstOrNull ?? (authorName == null ? null : ArtistRef(name: authorName)),
    thumbnails: parseThumbnails(header['thumbnail']),
    subtitle: sub.text,
    songCountText: textOf(header['secondSubtitle']),
  );

  final secondary = _twoColumnSecondary(data);
  final shelf =
      nav<Json>(secondary, ['contents', 0, 'musicPlaylistShelfRenderer']) ??
      nav<Json>(secondary, ['contents', 0, 'musicShelfRenderer']) ??
      const {};
  final rows = navList(shelf, ['contents']);
  return PlaylistPage(
    playlist: playlist,
    songs: _items(rows, parseAnyItem).whereType<SongItem>().toList(),
    description: _description(header),
    secondSubtitle: textOf(header['secondSubtitle']),
    continuation: continuationOf(shelf, rows) ?? continuationOf(secondary),
  );
}

PlaylistContinuation parsePlaylistContinuation(Json data) {
  final shelf = nav<Json>(data, ['continuationContents', 'musicPlaylistShelfContinuation']);
  final appended = navList(data, [
    'onResponseReceivedActions',
    0,
    'appendContinuationItemsAction',
    'continuationItems',
  ]);
  if (shelf != null || appended.isNotEmpty) {
    final rows = shelf != null ? navList(shelf, ['contents']) : appended;
    return PlaylistContinuation(
      songs: _items(rows, parseAnyItem).whereType<SongItem>().toList(),
      continuation: continuationOf(shelf, rows),
    );
  }
  final sections = parseSectionListContinuation(data);
  return PlaylistContinuation(songs: const [], sections: sections.sections, continuation: sections.continuation);
}

ArtistPage parseArtist(Json data, String browseId) {
  final header =
      nav<Json>(data, ['header', 'musicImmersiveHeaderRenderer']) ??
      nav<Json>(data, ['header', 'musicVisualHeaderRenderer']) ??
      const {};
  final wrappers = navList(_singleColumnSectionList(data), ['contents']);
  final description = wrappers
      .map((w) => textOf(nav(w, ['musicDescriptionShelfRenderer', 'description'])))
      .nonNulls
      .firstOrNull;
  return ArtistPage(
    artist: ArtistItem(
      browseId: browseId,
      title: textOf(header['title']) ?? '',
      thumbnails: parseThumbnails(header['thumbnail']),
    ),
    sections: parseSections(wrappers),
    description: description ?? textOf(header['description']),
    subscriberCount: textOf(nav(header, ['subscriptionButton', 'subscribeButtonRenderer', 'subscriberCountText'])),
    monthlyAudience: textOf(header['monthlyListenerCount']),
    shuffleEndpoint: parseWatchEndpoint(nav(header, ['playButton', 'buttonRenderer', 'navigationEndpoint'])),
    radioEndpoint: parseWatchEndpoint(nav(header, ['startRadioButton', 'buttonRenderer', 'navigationEndpoint'])),
  );
}

// ---------------------------------------------------------------------------------------------
// Watch next (queue, lyrics, related)
// ---------------------------------------------------------------------------------------------

List<SongItem> _panelSongs(List<Json> contents) => [
  for (final c in contents)
    if (parsePlaylistPanelVideo(
          (c['playlistPanelVideoRenderer'] ??
                  nav(c, ['playlistPanelVideoWrapperRenderer', 'primaryRenderer', 'playlistPanelVideoRenderer']) ??
                  const <String, dynamic>{})
              as Json,
        )
        case final SongItem s)
      s,
];

NextPage parseNext(Json data) {
  final tabs = navList(data, [
    'contents',
    'singleColumnMusicWatchNextResultsRenderer',
    'tabbedRenderer',
    'watchNextTabbedResultsRenderer',
    'tabs',
  ]);
  final panel =
      nav<Json>(tabs.firstOrNull, [
        'tabRenderer',
        'content',
        'musicQueueRenderer',
        'content',
        'playlistPanelRenderer',
      ]) ??
      const {};
  BrowseEndpoint? lyrics, related;
  for (final t in tabs) {
    final ep = parseBrowseEndpoint(nav(t, ['tabRenderer', 'endpoint']));
    if (ep == null) continue;
    final type = pageTypeOf(nav(t, ['tabRenderer', 'endpoint']));
    if (type == 'MUSIC_PAGE_TYPE_TRACK_LYRICS') lyrics = ep;
    if (type == 'MUSIC_PAGE_TYPE_TRACK_RELATED') related = ep;
  }
  final contents = navList(panel, ['contents']);
  return NextPage(
    items: _panelSongs(contents),
    playlistId: panel['playlistId'] as String?,
    continuation: continuationOf(panel, contents),
    lyricsEndpoint: lyrics,
    relatedEndpoint: related,
  );
}

NextPage parseNextContinuation(Json data) {
  final panel = nav<Json>(data, ['continuationContents', 'playlistPanelContinuation']) ?? const {};
  final contents = navList(panel, ['contents']);
  return NextPage(
    items: _panelSongs(contents),
    playlistId: panel['playlistId'] as String?,
    continuation: continuationOf(panel, contents),
  );
}

Lyrics? parseLyrics(Json data) {
  final shelf = nav<Json>(data, ['contents', 'sectionListRenderer', 'contents', 0, 'musicDescriptionShelfRenderer']);
  final text = textOf(shelf?['description']);
  if (text == null || text.isEmpty) return null;
  return Lyrics(text: text.replaceAll('\r\n', '\n'), source: textOf(shelf?['footer']));
}

List<Section> parseRelated(Json data) => parseSections(navList(data, ['contents', 'sectionListRenderer', 'contents']));
