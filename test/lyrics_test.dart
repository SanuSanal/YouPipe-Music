import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/data/lyrics/lrc.dart';
import 'package:youpipe_music/data/lyrics/lyrics_service.dart';

void main() {
  group('parseLrc', () {
    test('parses timestamps with 2- and 3-digit fractions and keeps blank lines', () {
      final lines = parseLrc('[ar:Coldplay]\n[00:35.66] Look at the stars\n[00:38.460] Look how they shine\n[00:40.36] \n');
      expect(lines, hasLength(3));
      expect(lines[0].start, const Duration(seconds: 35, milliseconds: 660));
      expect(lines[0].text, 'Look at the stars');
      expect(lines[1].start, const Duration(seconds: 38, milliseconds: 460));
      expect(lines[2].text, isEmpty);
    });

    test('expands multi-tag lines and sorts them', () {
      final lines = parseLrc('[00:10.00][01:20.00]Chorus\n[00:30.00]Verse');
      expect(lines.map((l) => l.text), ['Chorus', 'Verse', 'Chorus']);
      expect(lines.last.start, const Duration(minutes: 1, seconds: 20));
    });

    test('applies offset (positive = earlier)', () {
      final lines = parseLrc('[offset:+500]\n[00:10.00]Line');
      expect(lines.single.start, const Duration(seconds: 9, milliseconds: 500));
    });
  });

  test('activeLineIndex', () {
    final lines = parseLrc('[00:10.00]a\n[00:20.00]b\n[00:30.00]c');
    expect(activeLineIndex(lines, const Duration(seconds: 5)), -1);
    expect(activeLineIndex(lines, const Duration(seconds: 10)), 0);
    expect(activeLineIndex(lines, const Duration(seconds: 25)), 1);
    expect(activeLineIndex(lines, const Duration(minutes: 5)), 2);
  });

  test('cleanTitle strips video decorations and features', () {
    expect(cleanTitle('Yellow (Official Video)'), 'Yellow');
    expect(cleanTitle('Despacito (feat. Daddy Yankee)'), 'Despacito');
    expect(cleanTitle('Song [Lyric Video]'), 'Song');
    expect(cleanTitle('Moon Music'), 'Moon Music');
    expect(cleanArtist('Coldplay - Topic'), 'Coldplay');
  });
}
