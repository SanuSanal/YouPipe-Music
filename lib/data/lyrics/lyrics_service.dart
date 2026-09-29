import 'package:dio/dio.dart';

import '../../innertube/innertube.dart';
import 'lrc.dart';

class SongLyrics {
  const SongLyrics({this.synced, this.plain, required this.source});

  /// Time-coded lines when available.
  final List<LyricLine>? synced;
  final String? plain;
  final String source;

  bool get isSynced => synced != null && synced!.isNotEmpty;
}

/// Tidies YouTube titles/artists into what lyric databases index.
String cleanTitle(String title) => title
    .replaceAll(
      RegExp(
        r'\s*[\(\[][^\)\]]*(official|video|audio|lyric|visuali[sz]er|mv|hd|4k)[^\)\]]*[\)\]]',
        caseSensitive: false,
      ),
      '',
    )
    .replaceAll(RegExp(r'\s*[\(\[](feat|ft|with)\.?\s[^\)\]]*[\)\]]', caseSensitive: false), '')
    .replaceAll(RegExp(r'\s+-\s+(topic|official).*$', caseSensitive: false), '')
    .trim();

String cleanArtist(String artist) => artist.replaceAll(RegExp(r'\s*-\s*Topic$'), '').trim();

/// Synced lyrics from LRCLIB (lrclib.net), falling back to YouTube Music's plain lyrics.
class LyricsService {
  LyricsService(this._yt, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://lrclib.net/api/',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'User-Agent': 'YouPipe Music/1.0 (Android; https://github.com/youpipe-music)'},
            ),
          );

  final InnerTube _yt;
  final Dio _dio;
  final _cache = <String, SongLyrics?>{};

  Future<SongLyrics?> lyricsFor(SongItem song, {Duration? duration}) async {
    if (_cache.containsKey(song.videoId)) return _cache[song.videoId];
    final result = await _lrclib(song, duration ?? song.duration) ?? await _youtube(song);
    _cache[song.videoId] = result;
    return result;
  }

  Future<SongLyrics?> _lrclib(SongItem song, Duration? duration) async {
    final title = cleanTitle(song.title);
    final artist = cleanArtist(song.artists.firstOrNull?.name ?? '');
    if (title.isEmpty) return null;
    final seconds = duration?.inSeconds;

    SongLyrics? fromJson(Map<String, dynamic> j) {
      if (j['instrumental'] == true) return const SongLyrics(plain: '♪ Instrumental ♪', source: 'LRCLIB');
      final synced = j['syncedLyrics'] as String?;
      final plain = j['plainLyrics'] as String?;
      if (synced != null && synced.trim().isNotEmpty) {
        return SongLyrics(synced: parseLrc(synced), plain: plain, source: 'LRCLIB');
      }
      if (plain != null && plain.trim().isNotEmpty) return SongLyrics(plain: plain, source: 'LRCLIB');
      return null;
    }

    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'get',
        queryParameters: {
          'track_name': title,
          'artist_name': artist,
          if (song.album != null) 'album_name': song.album!.name,
          'duration': ?seconds,
        },
      );
      final found = res.data == null ? null : fromJson(res.data!);
      if (found?.isSynced == true) return found;
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }

    // Exact lookup missed: search and pick the closest duration, preferring synced results.
    final res = await _dio.get<List<dynamic>>('search', queryParameters: {'track_name': title, 'artist_name': artist});
    final candidates =
        (res.data ?? const []).cast<Map<String, dynamic>>().where((c) {
          final d = (c['duration'] as num?)?.toDouble();
          return seconds == null || d == null || (d - seconds).abs() <= 4;
        }).toList()..sort((a, b) {
          final syncedA = (a['syncedLyrics'] as String?)?.isNotEmpty == true ? 0 : 1;
          final syncedB = (b['syncedLyrics'] as String?)?.isNotEmpty == true ? 0 : 1;
          if (syncedA != syncedB) return syncedA - syncedB;
          if (seconds == null) return 0;
          final da = ((a['duration'] as num? ?? 0) - seconds).abs();
          final db = ((b['duration'] as num? ?? 0) - seconds).abs();
          return da.compareTo(db);
        });
    for (final c in candidates) {
      final l = fromJson(c);
      if (l != null) return l;
    }
    return null;
  }

  Future<SongLyrics?> _youtube(SongItem song) async {
    final next = await _yt.next(WatchEndpoint(videoId: song.videoId));
    final ep = next.lyricsEndpoint;
    if (ep == null) return null;
    final lyrics = await _yt.lyrics(ep);
    if (lyrics == null) return null;
    return SongLyrics(plain: lyrics.text, source: lyrics.source ?? 'YouTube Music');
  }
}
