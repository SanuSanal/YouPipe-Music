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

/// A GitHub "new issue" link prefilled with [entries] (newest first), the app version and device.
/// The user reviews and submits it on GitHub. Entries that don't fit are left out, because GitHub
/// rejects very long URLs; the body says how many and points to "Copy all".
Uri githubIssueUrl({
  required String repo,
  required List<ErrorEntry> entries,
  required String appVersion,
  String? device,
  int maxEncodedLength = 6000,
}) {
  final first = entries.isEmpty ? 'Error report' : entries.first.message.split('\n').first;
  final title = entries.length == 1
      ? 'Error: ${first.length > 80 ? '${first.substring(0, 80)}…' : first}'
      : 'Error report (${entries.length} errors)';
  String body(List<ErrorEntry> shown) {
    final left = entries.length - shown.length;
    return [
      '**What happened**',
      '<!-- What were you doing when this happened? -->',
      '',
      '**App:** $appVersion',
      if (device != null) '**Device:** $device',
      '',
      '**Errors** (newest first, from the in-app Error log)',
      '```',
      ...shown.map((e) => e.toString()),
      '```',
      if (left > 0) '$left more not included here; use "Copy all" on the Error log page to add them.',
    ].join('\n');
  }

  Uri build(List<ErrorEntry> shown) =>
      Uri.https('github.com', '/$repo/issues/new', {'title': title, 'body': body(shown)});

  // Add entries while the link stays short enough.
  var shown = <ErrorEntry>[];
  for (final e in entries) {
    final next = [...shown, e];
    if (build(next).toString().length > maxEncodedLength) break;
    shown = next;
  }
  // The newest entry alone is too long (a big stack trace): send its message only.
  if (shown.isEmpty && entries.isNotEmpty) {
    final e = entries.first;
    final message = e.message.length > 500 ? '${e.message.substring(0, 500)}…' : e.message;
    shown = [ErrorEntry(time: e.time, source: e.source, message: message)];
  }
  return build(shown);
}

/// Shorthand for [ErrorLog.instance].
final errorLog = ErrorLog.instance;
