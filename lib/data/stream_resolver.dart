import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

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

  /// kbps.
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

/// A stream for video mode, with the User-Agent its client requires: either YouTube's muxed 360p
/// stream ([url]), or a local DASH manifest ([manifestPath]) joining HD video-only streams with audio.
class VideoStreamInfo {
  const VideoStreamInfo({required this.url, required this.userAgent, this.height, this.manifestPath});

  /// The muxed stream, or for a manifest one of the googlevideo URLs in it (for its expiry).
  final String url;
  final String userAgent;
  final int? height;
  final String? manifestPath;

  DateTime? get expiresAt {
    final s = Uri.tryParse(url)?.queryParameters['expire'];
    final secs = s == null ? null : int.tryParse(s);
    return secs == null ? null : DateTime.fromMillisecondsSinceEpoch(secs * 1000);
  }
}

enum AudioQuality { low, normal, high }

/// Video mode's quality (docs/playback.md): `auto` lets ExoPlayer pick 360p–1080p by bandwidth,
/// `high` keeps the tallest (up to 1080p), `dataSaver` plays the muxed 360p stream.
enum VideoQuality { auto, high, dataSaver }

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

    final best = pick(streams, quality);
    debugPrint('YouPipe: audio $videoId itag ${best.itag} ${best.codec} ${best.bitrate} kbps (${quality.name})');
    _cache[videoId] = best;
    return best;
  }

  /// Prefers Opus (better quality per bit). High takes the highest bitrate, low the lowest, and
  /// normal the highest at or below 100 kbps (Opus 250, ~70 kbps).
  @visibleForTesting
  static AudioStreamInfo pick(List<AudioStreamInfo> streams, AudioQuality quality) {
    final opus = streams.where((s) => s.isOpus).toList();
    final pool = (opus.isNotEmpty ? opus : List.of(streams))..sort((a, b) => a.bitrate.compareTo(b.bitrate));
    return switch (quality) {
      AudioQuality.high => pool.last,
      AudioQuality.low => pool.first,
      AudioQuality.normal => pool.lastWhere((s) => s.bitrate <= 100, orElse: () => pool.first),
    };
  }

  /// Drops every cached URL: after a network change they're bound to an old IP address.
  void clearCache() {
    _cache.clear();
    _videoCache.clear();
    _manifestCache.clear();
  }

  void invalidate(String videoId) {
    _cache.remove(videoId);
    _videoCache.remove(videoId);
    _manifestCache.removeWhere((k, _) => k.startsWith('$videoId/'));
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

  final _manifestCache = <String, VideoStreamInfo>{};

  /// HD video mode: a DASH manifest of the video-only streams up to 1080p plus the audio, saved to a
  /// local file that `video_player` (ExoPlayer) plays. Throws `NO_HD` when there's nothing to build it from.
  Future<VideoStreamInfo> resolveVideoManifest(String videoId, VideoQuality quality) async {
    final key = '$videoId/${quality.name}';
    final cached = _manifestCache[key];
    final expiry = cached?.expiresAt;
    if (cached != null &&
        expiry != null &&
        expiry.isAfter(DateTime.now().add(const Duration(minutes: 10))) &&
        File(cached.manifestPath!).existsSync()) {
      return cached;
    }
    final Map<Object?, Object?> r;
    try {
      r = (await _channel.invokeMapMethod<Object?, Object?>('getVideoManifest', {
        'videoId': videoId,
        'hl': hl,
        'gl': gl,
        'maxHeight': 1080,
        'onlyBest': quality == VideoQuality.high,
      }))!;
    } on PlatformException catch (e) {
      throw StreamResolveException(e.code, e.message ?? 'Video extraction failed');
    }
    final mpd = r['mpd'] as String;
    final dir = Directory('${(await getTemporaryDirectory()).path}/video');
    await dir.create(recursive: true);
    final file = File('${dir.path}/${videoId}_${quality.name}.mpd');
    await file.writeAsString(mpd);
    final firstUrl = RegExp(r'<BaseURL>([^<]+)</BaseURL>').firstMatch(mpd)?.group(1)?.replaceAll('&amp;', '&') ?? '';
    final info = VideoStreamInfo(
      url: firstUrl,
      userAgent: r['userAgent'] as String,
      height: r['height'] as int?,
      manifestPath: file.path,
    );
    _manifestCache[key] = info;
    return info;
  }
}
