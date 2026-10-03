import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/data/stream_resolver.dart';
import 'package:youpipe_music/innertube/models.dart';
import 'package:youpipe_music/player/playable_source.dart';

const _song = SongItem(videoId: 'song', title: 'Oru Chembaneer', artists: []);

AudioStreamInfo _stream(String id) => AudioStreamInfo(url: 'https://example.invalid/$id', itag: 251);

/// [streams] maps a video id to its stream, or to the error code resolving it throws.
PlayableSource _source(Map<String, String?> streams, {String? video, List<String>? calls}) => PlayableSource(
  resolve: (id, {forceRefresh = false}) async {
    calls?.add(id);
    final code = streams[id];
    if (code != null) throw StreamResolveException(code, 'failed $id');
    return _stream(id);
  },
  findVideo: (_) async => video,
);

void main() {
  test('plays the song itself when it is available', () async {
    final (stream, id) = await _source({'song': null}, video: 'video').audioFor(_song);
    expect(id, 'song');
    expect(stream.url, endsWith('/song'));
  });

  test("plays the music video's audio when the song is unavailable, and remembers it", () async {
    final calls = <String>[];
    final source = _source({'song': 'UNAVAILABLE', 'video': null}, video: 'video', calls: calls);
    expect((await source.audioFor(_song)).$2, 'video');
    expect(source.fallbackFor('song'), 'video');
    expect((await source.audioFor(_song)).$2, 'video');
    expect(calls, ['song', 'video', 'video']);
  });

  test("throws the song's error when there is no video", () async {
    final source = _source({'song': 'GEO_RESTRICTED'});
    await expectLater(
      source.audioFor(_song),
      throwsA(isA<StreamResolveException>().having((e) => e.code, 'code', 'GEO_RESTRICTED')),
    );
  });

  test("throws the song's error when the video is unavailable too", () async {
    final source = _source({'song': 'UNAVAILABLE', 'video': 'AGE_RESTRICTED'}, video: 'video');
    await expectLater(
      source.audioFor(_song),
      throwsA(isA<StreamResolveException>().having((e) => e.message, 'message', 'failed song')),
    );
    expect(source.fallbackFor('song'), isNull);
  });

  test('does not fall back on a network error', () async {
    final calls = <String>[];
    final source = _source({'song': 'EXTRACTION_FAILED'}, video: 'video', calls: calls);
    await expectLater(source.audioFor(_song), throwsA(isA<StreamResolveException>()));
    expect(calls, ['song']);
  });

  test('does not fall back to the song itself', () async {
    final source = _source({'song': 'UNAVAILABLE'}, video: 'song');
    await expectLater(source.audioFor(_song), throwsA(isA<StreamResolveException>()));
  });

  test('forget tries the song again', () async {
    final calls = <String>[];
    final source = _source({'song': 'UNAVAILABLE', 'video': null}, video: 'video', calls: calls);
    await source.audioFor(_song);
    source.forget('song');
    expect(source.fallbackFor('song'), isNull);
    await source.audioFor(_song);
    expect(calls, ['song', 'video', 'song', 'video']);
  });

  test('isUnavailable', () {
    expect(PlayableSource.isUnavailable(StreamResolveException('UNAVAILABLE', '')), isTrue);
    expect(PlayableSource.isUnavailable(StreamResolveException('NO_STREAMS', '')), isTrue);
    expect(PlayableSource.isUnavailable(StreamResolveException('RECAPTCHA', '')), isFalse);
    expect(PlayableSource.isUnavailable(Exception('x')), isFalse);
  });
}
