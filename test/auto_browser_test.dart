import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/data/db/app_database.dart';
import 'package:youpipe_music/data/download_manager.dart';
import 'package:youpipe_music/data/library_repository.dart';
import 'package:youpipe_music/data/stream_resolver.dart';
import 'package:youpipe_music/innertube/innertube.dart';
import 'package:youpipe_music/player/auto_browser.dart';

/// Serves recorded fixtures instead of hitting YouTube.
class _FixtureInterceptor extends Interceptor {
  Map<String, dynamic> _fixture(String name) =>
      jsonDecode(File('test/innertube/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final body = options.data as Map<String, dynamic>;
    final name = switch ((options.path, body['browseId'])) {
      ('browse', 'FEmusic_home') => 'home.json',
      ('browse', final String id) when id.startsWith('VL') => 'playlist.json',
      ('browse', final String id) when id.startsWith('MPREb') => 'album.json',
      ('search', _) => 'search_songs.json',
      _ => throw StateError('No fixture for ${options.path} $body'),
    };
    handler.resolve(Response(requestOptions: options, statusCode: 200, data: _fixture(name)));
  }
}

void main() {
  late AppDatabase db;
  late LibraryRepository library;
  late AutoBrowser browser;
  final played = <(List<SongItem>, int, String)>[];
  final radios = <SongItem>[];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    library = LibraryRepository(db);
    final dio = Dio(BaseOptions(baseUrl: 'https://music.youtube.com/youtubei/v1/'))
      ..interceptors.add(_FixtureInterceptor());
    browser = AutoBrowser(
      yt: InnerTube(dio: dio, visitorData: 'test'),
      library: library,
      downloads: DownloadManager(db, StreamResolver()),
      playSong: (s) async => radios.add(s),
      playList: (songs, i, title) async => played.add((songs, i, title)),
    );
    played.clear();
    radios.clear();
  });

  tearDown(() => db.close());

  test('root lists the top-level folders', () async {
    final root = await browser.children(AudioService.browsableRootId);
    expect(root.map((m) => m.title), ['Home', 'Liked music', 'Downloads', 'Playlists', 'History']);
    expect(root.every((m) => m.playable == false), isTrue);
  });

  test('home shelves open into playable playlists/albums', () async {
    final shelves = await browser.children('folder:home');
    expect(shelves, isNotEmpty);
    final first = await browser.children(shelves.first.id);
    expect(first, isNotEmpty);
    final playlistFolder = first.firstWhere((m) => m.id.startsWith('playlist:'));
    final songs = await browser.children(playlistFolder.id);
    expect(songs.every((m) => m.playable == true), isTrue);
    await browser.play(songs[3].id);
    expect(played.single.$2, 3);
    expect(played.single.$1, hasLength(songs.length));
  });

  test('liked music plays from the tapped song', () async {
    final page = await InnerTube(
      dio: Dio(BaseOptions(baseUrl: 'https://music.youtube.com/youtubei/v1/'))
        ..interceptors.add(_FixtureInterceptor()),
    ).search('x', filter: SearchFilter.songs);
    for (final s in page.items.whereType<SongItem>().take(3)) {
      await library.setLiked(s, true);
    }
    final liked = await browser.children('folder:liked');
    expect(liked, hasLength(3));
    await browser.play(liked[1].id);
    expect(played.single.$2, 1);
    expect(played.single.$3, 'Liked music');
  });

  test('voice search starts a radio from the top song', () async {
    await browser.playFromSearch('despacito');
    expect(radios.single.title, 'Despacito');
    final results = await browser.search('despacito');
    expect(results.first.playable, isTrue);
  });
}
