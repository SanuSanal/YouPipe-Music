import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/data/playback_proxy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('youpipe/playback_proxy');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return 'http://127.0.0.1:4000/s/t${calls.length}';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('a relayed manifest serves every stream through the proxy and keeps the rest', () async {
    const mpd =
        '<MPD><AdaptationSet mimeType="video/mp4">'
        '<Representation id="v0"><BaseURL>https://r1.googlevideo.com/videoplayback?itag=137&amp;clen=1000&amp;c=VISIONOS</BaseURL>'
        '<SegmentBase indexRange="700-900"><Initialization range="0-699"/></SegmentBase></Representation>'
        '</AdaptationSet><AdaptationSet mimeType="audio/webm">'
        '<Representation id="a0"><BaseURL>https://r1.googlevideo.com/videoplayback?itag=251&amp;c=VISIONOS</BaseURL>'
        '<SegmentBase indexRange="300-400"><Initialization range="0-299"/></SegmentBase></Representation>'
        '</AdaptationSet></MPD>';

    final relayed = await PlaybackProxy.relayManifest(mpd);

    expect(calls.map((c) => c.arguments['url']), [
      'https://r1.googlevideo.com/videoplayback?itag=137&clen=1000&c=VISIONOS',
      'https://r1.googlevideo.com/videoplayback?itag=251&c=VISIONOS',
    ]);
    // The size comes from `clen` when the URL has one.
    expect(calls.map((c) => c.arguments['contentLength']), [1000, null]);
    expect(
      relayed,
      mpd
          .replaceFirst(
            RegExp('<BaseURL>[^<]+itag=137[^<]+</BaseURL>'),
            '<BaseURL>http://127.0.0.1:4000/s/t1</BaseURL>',
          )
          .replaceFirst(
            RegExp('<BaseURL>[^<]+itag=251[^<]+</BaseURL>'),
            '<BaseURL>http://127.0.0.1:4000/s/t2</BaseURL>',
          ),
    );
  });
}
