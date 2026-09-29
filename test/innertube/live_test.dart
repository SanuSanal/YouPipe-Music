@Tags(['live'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/innertube/innertube.dart';

/// Smoke test against the real InnerTube API. Run when YouTube changes something:
///   flutter test --tags live --run-skipped
void main() {
  final yt = InnerTube();

  setUpAll(() => yt.ensureVisitorData());

  test('home + chip + continuation', () async {
    final home = await yt.home();
    expect(home.sections, isNotEmpty);
    expect(home.chips, isNotEmpty);
    final filtered = await yt.home(chip: home.chips.firstWhere((c) => c.title != 'Podcasts').endpoint);
    expect(filtered.sections, isNotEmpty);
    final more = await yt.sectionsContinuation(home.continuation!);
    expect(more.sections, isNotEmpty);
  });

  test('search + filter + continuation + suggestions', () async {
    final all = await yt.search('coldplay');
    expect(all.topResult, isNotNull);
    final songs = await yt.search('coldplay', filter: SearchFilter.songs);
    expect(songs.items.whereType<SongItem>(), isNotEmpty);
    final more = await yt.searchContinuation(songs.continuation!);
    expect(more.items.whereType<SongItem>(), isNotEmpty);
    final albums = await yt.search('coldplay', filter: SearchFilter.albums);
    expect(albums.items.whereType<AlbumItem>(), isNotEmpty);
    final suggestions = await yt.searchSuggestions('cold');
    expect(suggestions.queries, isNotEmpty);
  });

  test('album, artist, playlist, more-page', () async {
    final album = await yt.album('MPREb_78js9pEDBUZ');
    expect(album.songs, isNotEmpty);
    final artist = await yt.artist('UCIaFw5VBEK8qaW6nRpx_qnw');
    final albums = artist.sections.firstWhere((s) => s.title == 'Albums');
    final allAlbums = await yt.browseSections(albums.moreEndpoint!);
    expect(allAlbums.sections.expand((s) => s.items).whereType<AlbumItem>(), isNotEmpty);
    final playlist = await yt.playlist(album.album.playlistId!);
    expect(playlist.songs, isNotEmpty);
  });

  test('radio queue + continuation + lyrics + related', () async {
    final next = await yt.next(const WatchEndpoint(videoId: 'FXovf5dsRTw', playlistId: 'RDAMVMFXovf5dsRTw'));
    expect(next.items.length, greaterThan(10));
    final more = await yt.nextContinuation(next.continuation!, playlistId: next.playlistId);
    expect(more.items, isNotEmpty);
    expect(await yt.lyrics(next.lyricsEndpoint!), isNotNull);
    expect(await yt.related(next.relatedEndpoint!), isNotEmpty);
  });

  test('explore, charts, moods', () async {
    final explore = await yt.explore();
    expect(explore.shortcuts, isNotEmpty);
    for (final shortcut in explore.shortcuts) {
      final page = await yt.browseSections(shortcut.endpoint);
      expect(page.sections, isNotEmpty, reason: shortcut.title);
    }
  });
}
