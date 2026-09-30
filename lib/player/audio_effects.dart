import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/error_log.dart';

/// The equalizer's range and bands on this device.
@immutable
class EqInfo {
  const EqInfo({required this.minDb, required this.maxDb, required this.bandHz});

  final double minDb;
  final double maxDb;

  /// Center frequency of each band, in Hz.
  final List<double> bandHz;
}

sealed class EffectsStatus {
  const EffectsStatus();
}

/// No audio session yet: nothing has played since the player was (re)created.
class EffectsWaiting extends EffectsStatus {
  const EffectsWaiting();
}

/// The system refused the equalizer. Songs still play, without it.
class EffectsUnavailable extends EffectsStatus {
  const EffectsUnavailable();
}

class EffectsReady extends EffectsStatus {
  const EffectsReady(this.eq);

  final EqInfo eq;
}

/// The equalizer and loudness boost, attached natively to the player's audio session
/// (`AudioEffectsChannel.kt`). Best-effort: a failure is logged and never reaches playback.
///
/// The native side keeps the settings and applies them whenever a session is attached.
class AudioEffects {
  AudioEffects({MethodChannel? channel}) : _channel = channel ?? const MethodChannel('youpipe/effects');

  final MethodChannel _channel;

  final status = ValueNotifier<EffectsStatus>(const EffectsWaiting());

  Future<void> _attaching = Future.value();

  /// Attaches the effects to [session] (just_audio's `androidAudioSessionId`), or releases them
  /// when it's null. Calls run in order.
  Future<void> attach(int? session) => _attaching = _attaching.then((_) => _attach(session));

  Future<void> _attach(int? session) async {
    try {
      final r = await _channel.invokeMapMethod<String, Object?>('attach', {'session': session});
      if (r == null || r['session'] != true) {
        status.value = const EffectsWaiting();
        return;
      }
      final eq = r['eq'];
      if (eq is Map) {
        status.value = EffectsReady(
          EqInfo(
            minDb: (eq['minDb'] as num).toDouble(),
            maxDb: (eq['maxDb'] as num).toDouble(),
            bandHz: [for (final f in eq['bands'] as List) (f as num).toDouble()],
          ),
        );
      } else {
        status.value = const EffectsUnavailable();
        errorLog.add('effects', 'Equalizer unavailable: ${r['eqError'] ?? 'no parameters'}');
      }
      if (r['loudness'] != true) errorLog.add('effects', 'Loudness boost unavailable: ${r['loudnessError']}');
    } catch (e, st) {
      status.value = const EffectsUnavailable();
      errorLog.add('effects', e, stack: st);
    }
  }

  Future<void> setEqEnabled(bool enabled) => _call('setEqEnabled', {'enabled': enabled});

  /// Gains in dB, by band index.
  Future<void> setGains(List<double> gains) => _call('setGains', {'gains': gains});

  /// Loudness boost in dB; 0 turns it off.
  Future<void> setLoudness(double db) => _call('setLoudness', {'db': db});

  Future<void> _call(String method, Map<String, Object?> args) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } catch (e, st) {
      errorLog.add('effects', e, stack: st);
    }
  }
}
