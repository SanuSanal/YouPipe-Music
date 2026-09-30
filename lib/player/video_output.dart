import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../data/error_log.dart';
import '../data/stream_resolver.dart';
import 'cast.dart';

/// The song has no music video to show.
class NoVideoException implements Exception {
  const NoVideoException(this.videoId);

  final String videoId;

  @override
  String toString() => 'NoVideoException($videoId)';
}

/// Video mode's output (docs/playback.md): plays the song's music video with `video_player`
/// (ExoPlayer) on the full player, as the audio handler's active output. In HD it plays a local DASH
/// manifest that joins the video-only streams with the audio (docs/streaming.md); in data saver mode,
/// or when there's no HD, it plays YouTube's muxed 360p stream.
///
/// It keeps playing (as sound) in the background, so the notification and the lock screen player
/// carry on through the handler.
class VideoOutput implements RemotePlayback {
  VideoOutput({required this.findVideo, required this.resolve, required this.resolveHd, required this.quality});

  /// The music video for a song in the queue, or null when there's none.
  final Future<String?> Function(MediaItem song) findVideo;

  /// The muxed 360p stream.
  final Future<VideoStreamInfo> Function(String videoId) resolve;

  /// The HD manifest.
  final Future<VideoStreamInfo> Function(String videoId, VideoQuality quality) resolveHd;

  /// The video quality setting.
  final VideoQuality Function() quality;

  /// The player for the full player's video area; null until a video is ready.
  final controller = ValueNotifier<VideoPlayerController?>(null);

  /// The id of the video being played (for SponsorBlock).
  String? currentVideoId;

  final _status = ValueNotifier(const CastStatus(state: CastState.connected));
  final _player = StreamController<RemotePlayer>.broadcast();
  String? _key;
  int _loads = 0;

  @override
  ValueListenable<CastStatus> get status => _status;

  @override
  Stream<RemotePlayer> get player => _player.stream;

  @override
  Future<String?> load({
    required MediaItem item,
    String? localPath,
    Duration position = Duration.zero,
    bool autoplay = true,
  }) async {
    final key = 'video:${++_loads}';
    _key = key;
    final id = await findVideo(item);
    if (id == null) throw NoVideoException(item.id);
    final c = await _open(id, key);
    if (c == null) return key;
    if (_key != key) {
      await c.dispose();
      return key;
    }
    final old = controller.value;
    currentVideoId = id;
    controller.value = c;
    unawaited(old?.dispose());
    c.addListener(() => _emit(c, key));
    if (position > Duration.zero) await c.seekTo(position);
    if (autoplay) await c.play();
    return key;
  }

  /// HD first (unless data saver is on), then the muxed 360p stream. Null when a newer load took over.
  Future<VideoPlayerController?> _open(String id, String key) async {
    final options = VideoPlayerOptions(allowBackgroundPlayback: true, mixWithOthers: true);
    final quality = this.quality();
    if (quality != VideoQuality.dataSaver) {
      VideoPlayerController? hd;
      try {
        final stream = await resolveHd(id, quality);
        if (_key != key) return null;
        // A file URI still goes through the plugin's HTTP data source, so the manifest's googlevideo
        // requests carry the User-Agent.
        hd = VideoPlayerController.networkUrl(
          Uri.file(stream.manifestPath!),
          formatHint: VideoFormat.dash,
          httpHeaders: {'User-Agent': stream.userAgent},
          videoPlayerOptions: options,
        );
        await hd.initialize();
        debugPrint('YouPipe: video $id in HD, starting at ${hd.value.size.height.round()}p, up to ${stream.height}p');
        return hd;
      } catch (e) {
        errorLog.add('video', 'No HD, using 360p: $e', detail: id);
        unawaited(hd?.dispose());
        if (_key != key) return null;
      }
    }
    final stream = await resolve(id);
    if (_key != key) return null;
    final c = VideoPlayerController.networkUrl(
      Uri.parse(stream.url),
      httpHeaders: {'User-Agent': stream.userAgent},
      videoPlayerOptions: options,
    );
    await c.initialize();
    return c;
  }

  void _emit(VideoPlayerController c, String key) {
    if (_key != key) return;
    final v = c.value;
    final RemoteState state;
    String? reason;
    if (v.hasError) {
      state = RemoteState.idle;
      reason = 'error';
    } else if (v.isCompleted) {
      state = RemoteState.idle;
      reason = 'finished';
    } else if (v.isBuffering) {
      state = RemoteState.buffering;
    } else {
      state = v.isPlaying ? RemoteState.playing : RemoteState.paused;
    }
    _player.add(
      RemotePlayer(
        state: state,
        idleReason: reason,
        position: v.position,
        duration: v.duration > Duration.zero ? v.duration : null,
        url: key,
      ),
    );
  }

  @override
  Future<void> play() async => controller.value?.play();

  @override
  Future<void> pause() async => controller.value?.pause();

  @override
  Future<void> seek(Duration position) async => controller.value?.seekTo(position);

  @override
  Future<void> setVolume(double volume) async => controller.value?.setVolume(volume);

  /// Leaving video mode: stop and free the player.
  Future<void> release() async {
    _key = null;
    currentVideoId = null;
    final c = controller.value;
    controller.value = null;
    await c?.dispose();
  }
}
