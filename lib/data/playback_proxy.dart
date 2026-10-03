import 'package:flutter/services.dart';

import 'stream_resolver.dart';

/// Plays googlevideo streams through PlaybackProxy.kt on 127.0.0.1, which fetches them in 1 MB
/// ranges. ExoPlayer's own open-ended request is throttled to about twice real time, so its buffer
/// never got far ahead (docs/streaming.md).
abstract final class PlaybackProxy {
  static const _channel = MethodChannel('youpipe/playback_proxy');

  /// The loopback URL that serves [stream].
  static Future<Uri> uriFor(AudioStreamInfo stream) async {
    final url = await _channel.invokeMethod<String>('url', {
      'url': stream.url,
      'mimeType': stream.mimeType,
      'contentLength': stream.contentLength,
    });
    return Uri.parse(url!);
  }
}
