import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/data/stream_resolver.dart';

AudioStreamInfo _stream(int itag, String codec, int kbps) => AudioStreamInfo(
  url: 'https://example.invalid/$itag',
  itag: itag,
  codec: codec,
  mimeType: codec == 'opus' ? 'audio/webm' : 'audio/mp4',
  bitrate: kbps,
);

void main() {
  final youtube = [
    _stream(140, 'mp4a.40.2', 129),
    _stream(251, 'opus', 135),
    _stream(249, 'opus', 51),
    _stream(250, 'opus', 67),
    _stream(139, 'mp4a.40.5', 48),
  ];

  test('prefers Opus and picks by quality', () {
    expect(StreamResolver.pick(youtube, AudioQuality.high).itag, 251);
    expect(StreamResolver.pick(youtube, AudioQuality.normal).itag, 250);
    expect(StreamResolver.pick(youtube, AudioQuality.low).itag, 249);
  });

  test('falls back to AAC when there is no Opus', () {
    final aac = youtube.where((s) => !s.isOpus).toList();
    expect(StreamResolver.pick(aac, AudioQuality.high).itag, 140);
    expect(StreamResolver.pick(aac, AudioQuality.normal).itag, 139);
    expect(StreamResolver.pick(aac, AudioQuality.low).itag, 139);
  });

  test('normal takes the lowest stream when all are above 100 kbps', () {
    final rich = [_stream(251, 'opus', 160), _stream(774, 'opus', 250)];
    expect(StreamResolver.pick(rich, AudioQuality.normal).itag, 251);
  });

  test('does not reorder the caller list', () {
    final aac = [_stream(140, 'mp4a.40.2', 129), _stream(139, 'mp4a.40.5', 48)];
    StreamResolver.pick(aac, AudioQuality.high);
    expect(aac.first.itag, 140);
  });
}
