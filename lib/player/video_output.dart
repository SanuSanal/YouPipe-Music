import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

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
/// (ExoPlayer) on the full player, as the audio handler's active output. v1 uses YouTube's muxed
/// progressive stream (360p, AAC audio), so there's no separate audio to keep in sync.
///
/// It keeps playing (as sound) in the background, so the notification and the lock screen player
/// carry on through the handler.
class VideoOutput implements RemotePlayback {
  VideoOutput({required this.findVideo, required this.resolve});

  /// The music video for a song in the queue, or null when there's none.
  final Future<String?> Function(MediaItem song) findVideo;
  final Future<VideoStreamInfo> Function(String videoId) resolve;

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
    final stream = await resolve(id);
    if (_key != key) return key;
    final c = VideoPlayerController.networkUrl(
      Uri.parse(stream.url),
      httpHeaders: {'User-Agent': stream.userAgent},
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true, mixWithOthers: true),
    );
    await c.initialize();
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
