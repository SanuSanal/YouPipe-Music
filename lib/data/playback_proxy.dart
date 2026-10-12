import 'package:flutter/services.dart';

import 'stream_resolver.dart';

/// Plays googlevideo streams through PlaybackProxy.kt on 127.0.0.1, which fetches them in 1 MB
/// ranges through the shared native client (docs/streaming.md):
/// - ExoPlayer's own open-ended request is throttled to about twice real time, so its buffer never
///   got far ahead;
/// - the native client keeps to the address family (IPv4/IPv6) extraction used after a bot check,
///   and ExoPlayer's own connections wouldn't.
abstract final class PlaybackProxy {
  static const _channel = MethodChannel('youpipe/playback_proxy');

  /// The loopback URL that serves the googlevideo [url].
  static Future<Uri> uri(String url, {String? mimeType, int? contentLength}) async {
    final relayed = await _channel.invokeMethod<String>('url', {
      'url': url,
      'mimeType': mimeType,
      'contentLength': contentLength,
    });
    return Uri.parse(relayed!);
  }

  /// The loopback URL that serves [stream].
  static Future<Uri> uriFor(AudioStreamInfo stream) =>
      uri(stream.url, mimeType: stream.mimeType, contentLength: stream.contentLength);

  static final _baseUrl = RegExp(r'<BaseURL>([^<]+)</BaseURL>');

  /// The DASH manifest [mpd] with every stream in it served through the proxy. Each call registers
  /// fresh loopback URLs, so relay the manifest for each load rather than caching the result.
  static Future<String> relayManifest(String mpd) async {
    final out = StringBuffer();
    var last = 0;
    for (final m in _baseUrl.allMatches(mpd)) {
      final url = _unescapeXml(m.group(1)!);
      // googlevideo URLs carry their size (`clen`), which saves the proxy a request per stream.
      final size = int.tryParse(Uri.tryParse(url)?.queryParameters['clen'] ?? '');
      final relayed = await uri(url, contentLength: size);
      out
        ..write(mpd.substring(last, m.start))
        ..write('<BaseURL>$relayed</BaseURL>');
      last = m.end;
    }
    out.write(mpd.substring(last));
    return out.toString();
  }

  static String _unescapeXml(String s) => s
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');
}
