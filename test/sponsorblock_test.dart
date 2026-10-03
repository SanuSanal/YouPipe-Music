import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/data/sponsorblock.dart';

/// Answers every request with one `music_offtopic` segment for [videoId], after [gate] completes.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.videoId);

  final String videoId;
  final gate = Completer<void>();
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    await gate.future;
    final body = jsonEncode([
      {
        'videoID': videoId,
        'segments': [
          {
            'segment': [0, 12.5],
          },
        ],
      },
    ]);
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('callers asking for the same video at once share one request, then the cache', () async {
    final adapter = _FakeAdapter('abc');
    final service = SponsorBlockService(
      dio: Dio(BaseOptions(baseUrl: 'https://example.invalid/'))..httpClientAdapter = adapter,
    );
    final calls = [service.segmentsFor('abc'), service.segmentsFor('abc'), service.segmentsFor('abc')];
    adapter.gate.complete();
    final results = await Future.wait(calls);
    expect(adapter.requests, 1);
    expect(results.map((r) => r.single.end), everyElement(const Duration(milliseconds: 12500)));
    await service.segmentsFor('abc');
    expect(adapter.requests, 1);
  });
}
