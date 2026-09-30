import 'package:flutter/services.dart';

/// The Resso-style lock screen player (LockScreenActivity.kt, docs/playback.md).
///
/// Android only lets a background app show it with "Display over other apps", so the setting
/// can only be turned on once that permission is granted.
abstract final class LockScreenPlayer {
  static const _channel = MethodChannel('youpipe/lockscreen');

  /// Whether "Display over other apps" is granted.
  static Future<bool> canShow() async => await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;

  /// Opens the system page where the user grants "Display over other apps".
  static Future<void> requestPermission() => _channel.invokeMethod('requestOverlay');
}
