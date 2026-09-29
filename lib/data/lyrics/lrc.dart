/// LRC ("[mm:ss.xx] text") parsing for synced lyrics.
library;

class LyricLine {
  const LyricLine(this.start, this.text);

  final Duration start;

  /// Empty for instrumental gaps.
  final String text;

  @override
  String toString() => '[$start] $text';
}

final _timeTag = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
final _offsetTag = RegExp(r'^\[offset:\s*([+-]?\d+)\]', caseSensitive: false);

Duration _parseTag(Match m) {
  final minutes = int.parse(m.group(1)!);
  final seconds = int.parse(m.group(2)!);
  final frac = m.group(3);
  // "5" = 500ms, "50" = 500ms, "500" = 500ms.
  final millis = frac == null ? 0 : int.parse(frac.padRight(3, '0').substring(0, 3));
  return Duration(minutes: minutes, seconds: seconds, milliseconds: millis);
}

/// Parses LRC text into time-ordered lines. Lines may carry several time tags
/// (`[00:10.00][01:20.00]chorus`); metadata tags other than `[offset:]` are ignored.
List<LyricLine> parseLrc(String lrc) {
  var offset = Duration.zero;
  final lines = <LyricLine>[];
  for (final raw in lrc.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final off = _offsetTag.firstMatch(line);
    if (off != null) {
      // Positive offset = lyrics appear earlier.
      offset = Duration(milliseconds: -int.parse(off.group(1)!));
      continue;
    }
    final tags = <Duration>[];
    var rest = line;
    while (true) {
      final m = _timeTag.matchAsPrefix(rest);
      if (m == null) break;
      tags.add(_parseTag(m));
      rest = rest.substring(m.end);
    }
    if (tags.isEmpty) continue;
    final text = rest.trim();
    for (final t in tags) {
      final start = t + offset;
      lines.add(LyricLine(start.isNegative ? Duration.zero : start, text));
    }
  }
  lines.sort((a, b) => a.start.compareTo(b.start));
  return lines;
}

/// Index of the line being sung at [position], or -1 before the first line.
int activeLineIndex(List<LyricLine> lines, Duration position) {
  var lo = 0, hi = lines.length - 1, found = -1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    if (lines[mid].start <= position) {
      found = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return found;
}
