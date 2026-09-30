import 'package:flutter/foundation.dart';

@immutable
class ErrorEntry {
  const ErrorEntry({required this.time, required this.source, required this.message, this.detail});

  final DateTime time;

  /// Where it happened, e.g. "player", "stream", "download".
  final String source;
  final String message;

  /// Extra context: the song, a stack trace.
  final String? detail;

  @override
  String toString() => '${time.toIso8601String()} [$source] $message${detail == null ? '' : '\n$detail'}';
}

/// The last errors of this app session, kept in memory only (nothing is saved or sent anywhere).
/// Shown on the hidden Error log page: tap the version in Settings → About three times.
class ErrorLog {
  ErrorLog._();

  static final instance = ErrorLog._();

  static const _max = 200;

  /// Newest first.
  final entries = ValueNotifier<List<ErrorEntry>>(const []);

  void add(String source, Object error, {String? detail, StackTrace? stack}) {
    final extra = [?detail, if (stack != null) _trim(stack)].join('\n');
    final entry = ErrorEntry(
      time: DateTime.now(),
      source: source,
      message: '$error',
      detail: extra.isEmpty ? null : extra,
    );
    debugPrint('YouPipe: [$source] $error${detail == null ? '' : ' ($detail)'}');
    final list = [entry, ...entries.value];
    entries.value = list.length > _max ? list.sublist(0, _max) : list;
  }

  void clear() => entries.value = const [];

  static String _trim(StackTrace stack) => stack.toString().split('\n').take(12).join('\n');
}

/// Shorthand for [ErrorLog.instance].
final errorLog = ErrorLog.instance;
