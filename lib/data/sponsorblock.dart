import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// A stretch of a video to skip, in playback time.
class SkipSegment {
  const SkipSegment(this.start, this.end);

  final Duration start;
  final Duration end;

  bool contains(Duration p) => p >= start && p < end - const Duration(milliseconds: 300);
}

/// SponsorBlock "non-music section" segments (intros, skits, outros in music videos).
///
/// Uses the hash-prefix endpoint, so only the first 4 hex chars of sha256(videoId) leave the device.
class SponsorBlockService {
  SponsorBlockService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://sponsor.ajay.app/api/',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  final Dio _dio;
  final _cache = <String, List<SkipSegment>>{};
  final _pending = <String, Future<List<SkipSegment>>>{};

  Future<List<SkipSegment>> segmentsFor(String videoId) {
    final cached = _cache[videoId];
    if (cached != null) return Future.value(cached);
    // Callers asking for the same video at once share one request.
    // (A block body: whenComplete would wait for the future remove() returns, which is this one.)
    return _pending[videoId] ??= _fetch(videoId).whenComplete(() {
      _pending.remove(videoId);
    });
  }

  Future<List<SkipSegment>> _fetch(String videoId) async {
    final prefix = sha256.convert(utf8.encode(videoId)).toString().substring(0, 4);
    List<SkipSegment> result;
    try {
      final res = await _dio.get<List<dynamic>>(
        'skipSegments/$prefix',
        queryParameters: {
          'categories': jsonEncode(['music_offtopic']),
          'actionType': 'skip',
        },
      );
      final entry = (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .where((e) => e['videoID'] == videoId)
          .firstOrNull;
      result = [
        for (final s in (entry?['segments'] as List? ?? const []).cast<Map<String, dynamic>>())
          if (s['segment'] case [final num start, final num end] when end - start >= 1)
            SkipSegment(Duration(milliseconds: (start * 1000).round()), Duration(milliseconds: (end * 1000).round())),
      ];
    } on DioException catch (e) {
      // 404 = no segments for any video with this prefix.
      if (e.response?.statusCode != 404) rethrow;
      result = const [];
    }
    _cache[videoId] = result;
    return result;
  }
}
