import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/data/error_log.dart';
import 'package:youpipe_music/player/audio_effects.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('youpipe/effects');
  final calls = <MethodCall>[];
  late Object? Function(MethodCall) reply;

  setUp(() {
    calls.clear();
    errorLog.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('an equalizer the system refuses is reported unavailable, without throwing', () async {
    reply = (_) => {'session': true, 'eq': null, 'eqError': 'UnsupportedOperationException', 'loudness': true};
    final fx = AudioEffects();
    await fx.attach(42);
    expect(fx.status.value, isA<EffectsUnavailable>());
    expect(errorLog.entries.value, hasLength(1));
    expect(errorLog.entries.value.single.message, contains('UnsupportedOperationException'));
  });

  test('attached bands are exposed', () async {
    reply = (_) => {
      'session': true,
      'eq': {
        'minDb': -15.0,
        'maxDb': 15.0,
        'bands': [60.0, 230.0, 910.0, 3600.0, 14000.0],
      },
      'loudness': true,
    };
    final fx = AudioEffects();
    await fx.attach(42);
    final status = fx.status.value as EffectsReady;
    expect(status.eq.bandHz, [60.0, 230.0, 910.0, 3600.0, 14000.0]);
    expect(status.eq.minDb, -15);
    expect(errorLog.entries.value, isEmpty);
  });

  test('no session means waiting', () async {
    reply = (_) => {'session': false};
    final fx = AudioEffects();
    await fx.attach(null);
    expect(fx.status.value, isA<EffectsWaiting>());
    expect(calls.single.arguments, {'session': null});
  });

  test('a channel failure is logged, not thrown', () async {
    reply = (_) => throw PlatformException(code: 'boom');
    final fx = AudioEffects();
    await fx.attach(42);
    await fx.setGains([1, 2]);
    expect(fx.status.value, isA<EffectsUnavailable>());
    expect(errorLog.entries.value, hasLength(2));
  });

  test('settings are sent in dB', () async {
    reply = (_) => null;
    final fx = AudioEffects();
    await fx.setGains([3, -2.5]);
    await fx.setLoudness(4);
    expect(calls.map((c) => c.method), ['setGains', 'setLoudness']);
    expect(calls[0].arguments, {
      'gains': [3.0, -2.5],
    });
    expect(calls[1].arguments, {'db': 4.0});
  });
}
