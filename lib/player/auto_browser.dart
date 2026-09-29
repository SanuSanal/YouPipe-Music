import 'package:audio_service/audio_service.dart';

import '../data/download_manager.dart';
import '../data/library_repository.dart';
import '../innertube/innertube.dart';
import 'audio_handler.dart';

/// Media browser tree for Android Auto (and other MediaBrowser clients such as Wear OS).
///
/// Ids: `folder:<name>` and `home:<n>`, `playlist:<id>`, `album:<id>`, `local:<id>` are browsable;
/// `<parent>|<index>` plays the list named by `<parent>` from `<index>`; `song:<videoId>` starts a radio.
class AutoBrowser {
  AutoBrowser({
    required this.yt,
    required this.library,
    required this.downloads,
    required this.playSong,
    required this.playList,
  });

  final InnerTube yt;
  final LibraryRepository library;
  final DownloadManager downloads;
  final Future<void> Function(SongItem song) playSong;
  final Future<void> Function(List<SongItem> songs, int index, String title) playList;

  /// Song lists shown under each parent, so a tap can play the whole list.
  final _lists = <String, (String, List<SongItem>)>{};
  final _songs = <String, SongItem>{};
  List<Section>? _homeSections;

  static const _gridHint = {'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT': 2};

  MediaItem _folder(String id, String title, {String? artUri, bool grid = false}) => MediaItem(
    id: id,
    title: title,
    playable: false,
    artUri: artUri == null ? null : Uri.parse(artUri),
    extras: grid ? _gridHint : null,
  );

  MediaItem _playable(String id, SongItem s) {
    _songs[s.videoId] = s;
    return YouPipeAudioHandler.toMediaItem(s).copyWith(id: id, playable: true);
  }

  List<MediaItem> _songList(String parent, String title, List<SongItem> songs) {
    _lists[parent] = (title, songs);
    return [for (final (i, s) in songs.indexed) _playable('$parent|$i', s)];
  }

  Future<List<MediaItem>> children(String parentId) async {
    switch (parentId) {
      case AudioService.browsableRootId:
        return [
          _folder('folder:home', 'Home', grid: true),
          _folder('folder:liked', 'Liked music'),
          _folder('folder:downloads', 'Downloads'),
          _folder('folder:playlists', 'Playlists', grid: true),
          _folder('folder:history', 'History'),
        ];
      case AudioService.recentRootId:
        return _songList('folder:history', 'History', (await library.watchHistory(limit: 10).first));
      case 'folder:home':
        final home = await yt.home();
        _homeSections = home.sections;
        return [
          for (final (i, s) in home.sections.indexed)
            _folder('home:$i', s.title, artUri: s.items.firstOrNull?.thumbnails.best(544)),
        ];
      case 'folder:liked':
        return _songList(parentId, 'Liked music', await library.watchLikedSongs().first);
      case 'folder:downloads':
        final done = (await downloads.watchAll().first).where((d) => d.row.filePath != null).map((d) => d.song);
        return _songList(parentId, 'Downloads', done.toList());
      case 'folder:history':
        return _songList(parentId, 'History', await library.watchHistory(limit: 100).first);
      case 'folder:playlists':
        final local = await library.watchLocalPlaylists().first;
        final saved = await library.watchSavedPlaylists().first;
        return [
          for (final p in local) _folder('local:${p.id}', p.name, artUri: p.thumbnailUrl),
          for (final p in saved) _folder('playlist:${p.id}', p.title, artUri: p.thumbnails.best(544)),
        ];
    }

    final (kind, id) = switch (parentId.split(':')) {
      [final k, ...final rest] => (k, rest.join(':')),
      _ => ('', ''),
    };
    switch (kind) {
      case 'home':
        final sections = _homeSections ?? (await yt.home()).sections;
        final section = sections.elementAtOrNull(int.parse(id));
        if (section == null) return const [];
        final songs = section.items.whereType<SongItem>().toList();
        return [
          ..._songList(parentId, section.title, songs),
          for (final item in section.items)
            switch (item) {
              AlbumItem() => _folder('album:${item.browseId}', item.title, artUri: item.thumbnails.best(544)),
              PlaylistItem() => _folder('playlist:${item.id}', item.title, artUri: item.thumbnails.best(544)),
              _ => null,
            },
        ].nonNulls.toList();
      case 'playlist':
        final page = await yt.playlist(id);
        return _songList(parentId, page.playlist.title, page.songs);
      case 'album':
        final page = await yt.album(id);
        return _songList(parentId, page.album.title, page.songs);
      case 'local':
        final rows = await library.watchLocalPlaylistSongs(int.parse(id)).first;
        final name = await library.watchLocalPlaylistName(int.parse(id)).first;
        return _songList(parentId, name ?? 'Playlist', rows.map((r) => r.$2).toList());
    }
    return const [];
  }

  Future<void> play(String mediaId) async {
    final bar = mediaId.lastIndexOf('|');
    if (bar != -1) {
      final parent = mediaId.substring(0, bar);
      final index = int.parse(mediaId.substring(bar + 1));
      if (!_lists.containsKey(parent)) await children(parent);
      final (title, songs) = _lists[parent]!;
      await playList(songs, index, title);
    } else if (mediaId.startsWith('song:')) {
      final song = _songs[mediaId.substring(5)];
      if (song != null) await playSong(song);
    }
  }

  Future<List<MediaItem>> search(String query) async {
    final page = await yt.search(query, filter: SearchFilter.songs);
    final songs = page.items.whereType<SongItem>().take(20).toList();
    return [for (final s in songs) _playable('song:${s.videoId}', s)];
  }

  /// Voice: "play (query) on YouPipe Music". An empty query plays liked songs.
  Future<void> playFromSearch(String query) async {
    if (query.trim().isEmpty) {
      final liked = await library.watchLikedSongs().first;
      if (liked.isNotEmpty) await playList(liked, 0, 'Liked music');
      return;
    }
    final page = await yt.search(query, filter: SearchFilter.songs);
    final first = page.items.whereType<SongItem>().firstOrNull;
    if (first != null) await playSong(first);
  }
}
