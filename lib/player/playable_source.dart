import '../data/stream_resolver.dart';
import '../innertube/models.dart';

/// Resolves a song's audio stream, playing its music video's audio when YouTube won't serve the
/// song itself (docs/playback.md). Some "song" uploads (ATV) are blocked for anonymous clients while
/// a video of the same song plays fine.
class PlayableSource {
  PlayableSource({required this.resolve, required this.findVideo});

  final Future<AudioStreamInfo> Function(String videoId, {bool forceRefresh}) resolve;

  /// The music video for a song, or null when there's none.
  final Future<String?> Function(SongItem song) findVideo;

  /// Song id → the video id whose audio plays in its place.
  final _fallback = <String, String>{};

  /// The song can't be played and a retry won't change that: unavailable, age- or region-restricted,
  /// or without audio streams.
  static bool isUnavailable(Object e) =>
      e is StreamResolveException &&
      const {'UNAVAILABLE', 'AGE_RESTRICTED', 'GEO_RESTRICTED', 'NO_STREAMS'}.contains(e.code);

  /// The video id played in place of [videoId], if any.
  String? fallbackFor(String videoId) => _fallback[videoId];

  /// The stream for [song], and the id it came from: the song's own id, or its music video's when
  /// the song is unavailable. Throws the song's own error when neither plays. Other errors (no
  /// network, for example) don't fall back.
  Future<(AudioStreamInfo, String)> audioFor(SongItem song, {bool forceRefresh = false}) async {
    final known = _fallback[song.videoId];
    if (known != null) return (await resolve(known, forceRefresh: forceRefresh), known);
    try {
      return (await resolve(song.videoId, forceRefresh: forceRefresh), song.videoId);
    } catch (e, st) {
      if (!isUnavailable(e)) rethrow;
      final alt = await findVideo(song);
      if (alt == null || alt == song.videoId) rethrow;
      final AudioStreamInfo stream;
      try {
        stream = await resolve(alt, forceRefresh: forceRefresh);
      } catch (altError) {
        // The video is unavailable too: report the song's own error. Any other failure (no network,
        // for example) is retried like one of the song's.
        if (isUnavailable(altError)) Error.throwWithStackTrace(e, st);
        rethrow;
      }
      _fallback[song.videoId] = alt;
      return (stream, alt);
    }
  }

  /// Reload: try the song's own stream again.
  void forget(String videoId) => _fallback.remove(videoId);
}
