import 'package:flutter/services.dart';

class AudioStreamInfo {
  const AudioStreamInfo({
    required this.url,
    required this.itag,
    this.mimeType,
    this.codec,
    this.bitrate = 0,
    this.contentLength,
  });

  factory AudioStreamInfo.fromMap(Map<Object?, Object?> m) => AudioStreamInfo(
    url: m['url'] as String,
    itag: m['itag'] as int? ?? 0,
    mimeType: m['mimeType'] as String?,
    codec: m['codec'] as String?,
    bitrate: m['bitrate'] as int? ?? 0,
    contentLength: switch (m['contentLength']) {
      final int n when n > 0 => n,
      _ => null,
    },
  );

  final String url;
  final int itag;
  final String? mimeType;
  final String? codec;
  final int bitrate;
  final int? contentLength;

  bool get isOpus => (codec ?? '').contains('opus') || (mimeType ?? '').contains('webm');

  /// Stream URLs carry their own expiry (`expire=<unix seconds>`).
  DateTime? get expiresAt {
    final s = Uri.tryParse(url)?.queryParameters['expire'];
    final secs = s == null ? null : int.tryParse(s);
    return secs == null ? null : DateTime.fromMillisecondsSinceEpoch(secs * 1000);
  }
}

/// A muxed (video + audio) stream for video mode, with the User-Agent its client requires.
class VideoStreamInfo {
  const VideoStreamInfo({required this.url, required this.userAgent, this.height});

  final String url;
  final String userAgent;
  final int? height;

  DateTime? get expiresAt {
    final s = Uri.tryParse(url)?.queryParameters['expire'];
    final secs = s == null ? null : int.tryParse(s);
    return secs == null ? null : DateTime.fromMillisecondsSinceEpoch(secs * 1000);
  }
}

enum AudioQuality { low, high }

class StreamResolveException implements Exception {
  StreamResolveException(this.code, this.message);

  /// AGE_RESTRICTED, GEO_RESTRICTED, UNAVAILABLE, RECAPTCHA, EXTRACTION_FAILED, NO_STREAMS, NO_VIDEO
  final String code;
  final String message;

  @override
  String toString() => 'StreamResolveException($code): $message';
}

/// Turns a videoId into a playable audio URL via the native NewPipeExtractor channel.
class StreamResolver {
  StreamResolver({this.hl = 'en', this.gl = 'US', this.quality = AudioQuality.high});

  static const _channel = MethodChannel('youpipe/stream_extractor');

  String hl;
  String gl;
  AudioQuality quality;

  final _cache = <String, AudioStreamInfo>{};

  Future<AudioStreamInfo> resolve(String videoId, {bool forceRefresh = false}) async {
    final cached = _cache[videoId];
    final expiry = cached?.expiresAt;
    if (!forceRefresh &&
        cached != null &&
        expiry != null &&
        expiry.isAfter(DateTime.now().add(const Duration(minutes: 10)))) {
      return cached;
    }

    final Map<Object?, Object?> result;
    try {
      result =
          await _channel.invokeMapMethod<Object?, Object?>('getAudioStreams', {
            'videoId': videoId,
            'hl': hl,
            'gl': gl,
          }) ??
          const {};
    } on PlatformException catch (e) {
      throw StreamResolveException(e.code, e.message ?? 'Stream extraction failed');
    }

    final streams = ((result['streams'] as List?) ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(AudioStreamInfo.fromMap)
        .toList();
    if (streams.isEmpty) throw StreamResolveException('NO_STREAMS', 'No audio streams for $videoId');

    final best = _pick(streams);
    _cache[videoId] = best;
    return best;
  }

  /// Prefers Opus (better quality per bit) and picks the highest or lowest bitrate by setting.
  AudioStreamInfo _pick(List<AudioStreamInfo> streams) {
    final opus = streams.where((s) => s.isOpus).toList();
    final pool = opus.isNotEmpty ? opus : streams;
    pool.sort((a, b) => a.bitrate.compareTo(b.bitrate));
    return quality == AudioQuality.high ? pool.last : pool.first;
  }

  void invalidate(String videoId) {
    _cache.remove(videoId);
    _videoCache.remove(videoId);
  }

  final _videoCache = <String, VideoStreamInfo>{};

  /// Video mode: the muxed stream of a (music) video, at most 720p; in practice YouTube muxes 360p.
  Future<VideoStreamInfo> resolveVideo(String videoId) async {
    final cached = _videoCache[videoId];
    final expiry = cached?.expiresAt;
    if (cached != null && expiry != null && expiry.isAfter(DateTime.now().add(const Duration(minutes: 10)))) {
      return cached;
    }
    try {
      final r = await _channel.invokeMapMethod<Object?, Object?>('getVideoStream', {
        'videoId': videoId,
        'hl': hl,
        'gl': gl,
      });
      final info = VideoStreamInfo(
        url: r!['url'] as String,
        userAgent: r['userAgent'] as String,
        height: r['height'] as int?,
      );
      _videoCache[videoId] = info;
      return info;
    } on PlatformException catch (e) {
      throw StreamResolveException(e.code, e.message ?? 'Video extraction failed');
    }
  }
}
