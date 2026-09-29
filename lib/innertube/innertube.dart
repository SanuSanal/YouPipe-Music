import 'package:dio/dio.dart';

import 'auth.dart';
import 'clients.dart';
import 'json_nav.dart';
import 'models.dart';
import 'parsers/pages.dart';

export 'models.dart';

class InnerTubeException implements Exception {
  InnerTubeException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'InnerTubeException($statusCode): $message';
}

/// Search filters, as the `params` protobuf blobs YouTube Music web sends.
enum SearchFilter {
  songs('Songs', 'EgWKAQIIAWoSEAUQCRADEAQQChAOEBAQFRAR'),
  videos('Videos', 'EgWKAQIQAWoSEAUQCRADEAQQChAOEBAQFRAR'),
  albums('Albums', 'EgWKAQIYAWoSEAUQCRADEAQQChAOEBAQFRAR'),
  artists('Artists', 'EgWKAQIgAWoSEAUQCRADEAQQChAOEBAQFRAR'),
  communityPlaylists('Community playlists', 'EgeKAQQoAEABahIQBRAJEAMQBBAKEA4QEBAVEBE%3D'),
  featuredPlaylists('Featured playlists', 'EgeKAQQoADgBahIQBRAJEAMQBBAKEA4QEBAVEBE%3D');

  const SearchFilter(this.label, this.params);
  final String label;
  final String params;
}

/// YouTube Music InnerTube client (browse/search/next). Pure Dart, no Flutter imports.
class InnerTube {
  InnerTube({Dio? dio, this.hl = 'en', this.gl = 'US', this.visitorData})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://music.youtube.com/youtubei/v1/',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ),
          );

  final Dio _dio;
  String hl;
  String gl;

  /// Anonymous session id. Without it YouTube serves degraded/generic responses.
  String? visitorData;

  /// Google session cookie (from the sign-in WebView). When set, requests are authenticated.
  String? cookie;

  bool get signedIn => isSignedInCookie(cookie);

  Map<String, String> _headers() {
    final headers = _client.headers(visitorData: visitorData);
    final c = cookie;
    if (c != null && isSignedInCookie(c)) {
      headers['Cookie'] = c;
      headers['Authorization'] = sapisidHashHeader(c)!;
      headers['X-Goog-AuthUser'] = '0';
      headers['X-Origin'] = 'https://music.youtube.com';
    }
    return headers;
  }

  static const _client = YouTubeClient.webRemix;

  Future<Json> _post(String endpoint, Json body) async {
    try {
      final res = await _dio.post<Json>(
        endpoint,
        queryParameters: {'prettyPrint': 'false'},
        data: {
          'context': _client.context(hl: hl, gl: gl, visitorData: visitorData),
          ...body,
        },
        options: Options(headers: _headers()),
      );
      final data = res.data ?? const {};
      visitorData ??= nav<String>(data, ['responseContext', 'visitorData']);
      return data;
    } on DioException catch (e) {
      throw InnerTubeException(e.message ?? e.type.name, statusCode: e.response?.statusCode);
    }
  }

  Future<Json> _browse(BrowseEndpoint endpoint) =>
      _post('browse', {'browseId': endpoint.browseId, 'params': ?endpoint.params});

  Future<Json> _continuation(String endpoint, String token) => _post(endpoint, {'continuation': token});

  /// Fetches a fresh anonymous visitorData if we don't have one yet.
  Future<String?> ensureVisitorData() async {
    if (visitorData != null) return visitorData;
    final data = await _post('visitor_id', const {});
    return visitorData = nav<String>(data, ['responseContext', 'visitorData']);
  }

  // Home & explore -----------------------------------------------------------------------------

  /// Home feed; pass a chip's endpoint to filter it by mood.
  Future<HomePage> home({BrowseEndpoint? chip}) async =>
      parseHome(await _browse(chip ?? const BrowseEndpoint('FEmusic_home')));

  Future<SectionsPage> sectionsContinuation(String token) async =>
      parseSectionListContinuation(await _continuation('browse', token));

  Future<ExplorePage> explore() async => parseExplore(await _browse(const BrowseEndpoint('FEmusic_explore')));

  /// Charts, new releases, moods & genres, mood categories and every "More" button.
  Future<SectionsPage> browseSections(BrowseEndpoint endpoint) async => parseSectionsPage(await _browse(endpoint));

  // Search -------------------------------------------------------------------------------------

  Future<SearchPage> search(String query, {SearchFilter? filter}) async =>
      parseSearch(await _post('search', {'query': query, 'params': ?filter?.params}));

  Future<SearchPage> searchContinuation(String token) async =>
      parseSearchContinuation(await _continuation('search', token));

  Future<SearchSuggestions> searchSuggestions(String input) async =>
      parseSearchSuggestions(await _post('music/get_search_suggestions', {'input': input}));

  // Pages --------------------------------------------------------------------------------------

  Future<AlbumPage> album(String browseId) async => parseAlbum(await _browse(BrowseEndpoint(browseId)), browseId);

  Future<ArtistPage> artist(String browseId) async => parseArtist(await _browse(BrowseEndpoint(browseId)), browseId);

  Future<PlaylistPage> playlist(String playlistId) async {
    final browseId = playlistId.startsWith('VL') ? playlistId : 'VL$playlistId';
    return parsePlaylist(await _browse(BrowseEndpoint(browseId)), browseId);
  }

  Future<PlaylistContinuation> playlistContinuation(String token) async =>
      parsePlaylistContinuation(await _continuation('browse', token));

  // Watch next ---------------------------------------------------------------------------------

  /// Up-next queue for a song or playlist. For radio, pass `playlistId: 'RDAMVM$videoId'`.
  Future<NextPage> next(WatchEndpoint endpoint) async => parseNext(
    await _post('next', {
      'videoId': ?endpoint.videoId,
      'playlistId': ?endpoint.playlistId,
      'params': ?endpoint.params,
      'index': ?endpoint.index,
      'isAudioOnly': true,
      'enablePersistentPlaylistPanel': true,
      'tunerSettingValue': 'AUTOMIX_SETTING_NORMAL',
    }),
  );

  Future<NextPage> nextContinuation(String token, {String? playlistId}) async => parseNextContinuation(
    await _post('next', {
      'continuation': token,
      'playlistId': ?playlistId,
      'isAudioOnly': true,
      'enablePersistentPlaylistPanel': true,
    }),
  );

  Future<Lyrics?> lyrics(BrowseEndpoint endpoint) async => parseLyrics(await _browse(endpoint));

  // Account (signed in) ------------------------------------------------------------------------

  Future<AccountInfo?> accountInfo() async => parseAccountMenu(await _post('account/account_menu', const {}));

  /// Library pages: playlists, albums, artists, liked songs.
  Future<SectionsPage> library(LibraryPage page) async =>
      parseSectionsPage(await _browse(BrowseEndpoint(page.browseId)));

  Future<void> like(String videoId) => _post('like/like', {
    'target': {'videoId': videoId},
  });

  Future<void> removeLike(String videoId) => _post('like/removelike', {
    'target': {'videoId': videoId},
  });

  /// Saves/unsaves a playlist or album (by its playlist id) in the account library.
  Future<void> savePlaylist(String playlistId, {bool save = true}) => _post(save ? 'like/like' : 'like/removelike', {
    'target': {'playlistId': playlistId},
  });

  Future<void> subscribe(String channelId, {bool subscribe = true}) =>
      _post(subscribe ? 'subscription/subscribe' : 'subscription/unsubscribe', {
        'channelIds': [channelId],
      });

  /// Creates a private playlist; returns its id.
  Future<String?> createPlaylist(String title, {List<String> videoIds = const []}) async {
    final data = await _post('playlist/create', {
      'title': title,
      'privacyStatus': 'PRIVATE',
      if (videoIds.isNotEmpty) 'videoIds': videoIds,
    });
    return data['playlistId'] as String?;
  }

  Future<void> addToPlaylist(String playlistId, List<String> videoIds) => _post('browse/edit_playlist', {
    'playlistId': playlistId.startsWith('VL') ? playlistId.substring(2) : playlistId,
    'actions': [
      for (final id in videoIds) {'action': 'ACTION_ADD_VIDEO', 'addedVideoId': id},
    ],
  });

  Future<List<Section>> related(BrowseEndpoint endpoint) async => parseRelated(await _browse(endpoint));
}
