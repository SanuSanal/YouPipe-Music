import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/innertube/innertube.dart';
import 'package:youpipe_music/innertube/parsers/pages.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/innertube/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

final _videoId = RegExp(r'^[\w-]{11}$');

void main() {
  test('filtered song search', () {
    final page = parseSearch(fixture('search_songs.json'));
    final songs = page.items.whereType<SongItem>().toList();
    expect(songs.length, greaterThan(10));
    expect(songs.every((s) => _videoId.hasMatch(s.videoId)), isTrue);
    final top = songs.first;
    expect(top.title, 'Despacito');
    expect(top.artists.map((a) => a.name), containsAll(['Luis Fonsi', 'Daddy Yankee']));
    expect(top.artists.first.id, startsWith('UC'));
    expect(top.album?.id, startsWith('MPREb_'));
    expect(top.duration, const Duration(minutes: 3, seconds: 49));
    expect(top.isVideo, isFalse);
    expect(top.thumbnail!.sized(544), contains('=w544-h544'));
    expect(page.continuation, isNotNull);
  });

  test('unfiltered search has a top result and mixed item types', () {
    final page = parseSearch(fixture('search_all.json'));
    expect(page.topResult, isA<ArtistItem>());
    expect(page.topResult!.title, 'Coldplay');
    expect(page.topResultItems.whereType<SongItem>(), isNotEmpty);
    expect(page.items.whereType<AlbumItem>().map((a) => a.title), contains('Parachutes'));
    expect(page.items.whereType<ArtistItem>(), isNotEmpty);
    expect(page.items.whereType<PlaylistItem>(), isNotEmpty);
    final videos = page.items.whereType<SongItem>().where((s) => s.isVideo);
    expect(videos, isNotEmpty);
    final album = page.items.whereType<AlbumItem>().first;
    expect(album.year, '2000');
    expect(album.artists.single.name, 'Coldplay');
  });

  test('search suggestions', () {
    final s = parseSearchSuggestions(fixture('search_suggestions.json'));
    expect(s.queries, contains('coldplay'));
    expect(s.items, isNotEmpty);
  });

  test('home feed', () {
    final home = parseHome(fixture('home.json'));
    expect(home.chips.length, greaterThan(5));
    expect(home.sections, isNotEmpty);
    expect(home.sections.first.title, isNotEmpty);
    expect(home.sections.first.items.first, isA<PlaylistItem>());
    expect(home.continuation, isNotNull);

    final more = parseSectionListContinuation(fixture('home_continuation.json'));
    expect(more.sections, isNotEmpty);
    expect(more.sections.first.strapline, isNotNull);
  });

  test('album page', () {
    final page = parseAlbum(fixture('album.json'), 'MPREb_78js9pEDBUZ');
    expect(page.album.title, contains('Despacito'));
    expect(page.album.typeLabel, 'Single');
    expect(page.album.year, '2017');
    expect(page.album.artists.first.name, 'Luis Fonsi');
    expect(page.album.playlistId, startsWith('OLAK5uy_'));
    expect(page.songs, hasLength(1));
    expect(page.songs.single.videoId, 'kJQP7kiw5Fk');
    expect(page.songs.single.artists, isNotEmpty, reason: 'filled from header');
    expect(page.songs.single.duration, const Duration(minutes: 3, seconds: 49));
    expect(page.otherSections, isNotEmpty);
  });

  test('playlist page', () {
    final page = parsePlaylist(fixture('playlist.json'), 'VLRDCLAK5uy_kb7EBi6y3GrtJri4_ZH56Ms786DFEimbM');
    expect(page.playlist.title, 'Lofi Loft');
    expect(page.playlist.id, 'RDCLAK5uy_kb7EBi6y3GrtJri4_ZH56Ms786DFEimbM');
    expect(page.playlist.author?.name, 'YouTube Music');
    expect(page.songs, hasLength(86));
    final first = page.songs.first;
    expect(first.title, 'Still');
    expect(first.artists.map((a) => a.name), ['Idealism', 'Philanthrope']);
    expect(first.album?.name, 'Chillhop Daydreams 2');
    expect(first.duration, const Duration(minutes: 3, seconds: 34));
    expect(first.setVideoId, isNotNull);
    expect(page.continuation, isNotNull);

    final related = parsePlaylistContinuation(fixture('playlist_continuation.json'));
    expect(related.songs, isEmpty);
    expect(related.sections.first.title, 'Related playlists');
  });

  test('artist page', () {
    final page = parseArtist(fixture('artist.json'), 'UCIaFw5VBEK8qaW6nRpx_qnw');
    expect(page.artist.title, 'Coldplay');
    expect(page.artist.thumbnails, isNotEmpty);
    expect(page.subscriberCount, isNotNull);
    expect(page.description, isNotNull);
    expect(page.shuffleEndpoint, isNotNull);
    expect(page.radioEndpoint, isNotNull);
    final titles = page.sections.map((s) => s.title).toList();
    expect(titles, containsAll(['Top songs', 'Albums', 'Singles & EPs', 'Fans might also like']));
    final topSongs = page.sections.firstWhere((s) => s.title == 'Top songs');
    expect(topSongs.items.whereType<SongItem>(), hasLength(5));
    expect(topSongs.moreEndpoint, isNotNull);
    final albums = page.sections.firstWhere((s) => s.title == 'Albums');
    expect(albums.items.whereType<AlbumItem>(), isNotEmpty);
    expect(albums.moreEndpoint, isNotNull);
    final fans = page.sections.firstWhere((s) => s.title == 'Fans might also like');
    expect(fans.items.whereType<ArtistItem>(), isNotEmpty);
  });

  test('next / radio queue', () {
    final page = parseNext(fixture('next.json'));
    expect(page.items, hasLength(50));
    expect(page.items.first.videoId, 'FXovf5dsRTw');
    expect(page.items[1].artists, isNotEmpty);
    expect(page.items[1].duration, isNotNull);
    expect(page.continuation, isNotNull);
    expect(page.lyricsEndpoint?.browseId, startsWith('MPLY'));
    expect(page.relatedEndpoint?.browseId, startsWith('MPTR'));
  });

  test('lyrics and related', () {
    final lyrics = parseLyrics(fixture('lyrics.json'));
    expect(lyrics!.text, contains('Fonsi'));
    expect(lyrics.text, isNot(contains('\r')));
    expect(lyrics.source, contains('LyricFind'));

    final related = parseRelated(fixture('related.json'));
    expect(related.map((s) => s.title), contains('You might also like'));
    expect(related.first.items.whereType<SongItem>(), isNotEmpty);
  });

  test('explore, moods, charts, new releases', () {
    final explore = parseExplore(fixture('explore.json'));
    expect(explore.shortcuts.map((m) => m.title), ['New releases', 'Charts', 'Moods & genres']);
    expect(explore.sections.map((s) => s.title), contains('New albums & singles'));
    final moods = explore.sections.firstWhere((s) => s.title == 'Moods & genres');
    expect(moods.moods, isNotEmpty);
    final trending = explore.sections.firstWhere((s) => s.title == 'Trending');
    expect(trending.itemsPerColumn, 4);
    expect(trending.items.whereType<SongItem>(), isNotEmpty);

    final moodsPage = parseSectionsPage(fixture('moods.json'));
    expect(moodsPage.sections.map((s) => s.title), containsAll(['Moods & moments', 'Genres']));
    expect(moodsPage.sections.first.moods.first.color, isNotNull);

    final category = parseSectionsPage(fixture('mood_category.json'));
    expect(category.sections.first.items.whereType<PlaylistItem>(), isNotEmpty);

    final releases = parseSectionsPage(fixture('new_releases.json'));
    expect(releases.sections.single.items.whereType<AlbumItem>().length, greaterThan(50));

    final charts = parseSectionsPage(fixture('charts.json'));
    final artists = charts.sections.firstWhere((s) => s.title == 'Top artists');
    expect(artists.items.whereType<ArtistItem>(), isNotEmpty);
  });
}
