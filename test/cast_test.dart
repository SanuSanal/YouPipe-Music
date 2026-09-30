import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/player/cast.dart';
import 'package:youpipe_music/player/dlna.dart';

void main() {
  group('CastStatus.fromMap', () {
    test('reads a live session', () {
      final s = CastStatus.fromMap({'type': 'state', 'state': 'connected', 'device': 'Living Room TV', 'volume': 0.4});
      expect(s.connected, isTrue);
      expect(s.device, 'Living Room TV');
      expect(s.volume, 0.4);
    });

    test('defaults to no Cast support', () {
      final s = CastStatus.fromMap({'type': 'state'});
      expect(s.state, CastState.none);
      expect(s.connected, isFalse);
    });
  });

  group('RemotePlayer.fromMap', () {
    test('reads position, duration and the song URL', () {
      final p = RemotePlayer.fromMap({
        'type': 'player',
        'state': 'playing',
        'positionMs': 61500,
        'durationMs': 223000,
        'url': 'http://192.168.1.20:40000/a/abc',
      });
      expect(p.playing, isTrue);
      expect(p.position, const Duration(milliseconds: 61500));
      expect(p.duration, const Duration(seconds: 223));
      expect(p.url, 'http://192.168.1.20:40000/a/abc');
    });

    test('an unknown duration is null', () {
      expect(RemotePlayer.fromMap({'state': 'buffering', 'durationMs': 0}).duration, isNull);
    });
  });

  group('RemotePlayer.processingState', () {
    AudioProcessingState of(String state, [String? reason]) =>
        RemotePlayer.fromMap({'state': state, 'idleReason': reason}).processingState;

    test('maps the receiver states', () {
      expect(of('playing'), AudioProcessingState.ready);
      expect(of('paused'), AudioProcessingState.ready);
      expect(of('buffering'), AudioProcessingState.buffering);
    });

    test('a finished song completes, a failed one errors', () {
      expect(of('idle', 'finished'), AudioProcessingState.completed);
      expect(RemotePlayer.fromMap({'state': 'idle', 'idleReason': 'finished'}).finished, isTrue);
      expect(of('idle', 'error'), AudioProcessingState.error);
      expect(of('idle'), AudioProcessingState.loading);
    });
  });

  group('DLNA times', () {
    test('parses H:MM:SS with optional fractions', () {
      expect(parseDlnaTime('0:03:43'), const Duration(minutes: 3, seconds: 43));
      expect(parseDlnaTime('00:01:02.500'), const Duration(minutes: 1, seconds: 2, milliseconds: 500));
      expect(parseDlnaTime('NOT_IMPLEMENTED'), isNull);
      expect(parseDlnaTime(null), isNull);
    });

    test('formats seek targets', () {
      expect(formatDlnaTime(const Duration(minutes: 3, seconds: 7)), '0:03:07');
      expect(formatDlnaTime(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    });
  });
}
