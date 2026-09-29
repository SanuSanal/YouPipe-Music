import 'package:drift/drift.dart';

import '../innertube/models.dart';
import 'db/app_database.dart';

class LocalPlaylistSummary {
  const LocalPlaylistSummary({required this.id, required this.name, required this.songCount, this.thumbnailUrl});

  final int id;
  final String name;
  final int songCount;
  final String? thumbnailUrl;
}

/// Everything the user keeps locally: likes, history, saved items, own playlists, searches.
class LibraryRepository {
  LibraryRepository(this._db);

  final AppDatabase _db;

  Future<void> _upsertSong(SongItem s) => _db.into(_db.songs).insertOnConflictUpdate(songToCompanion(s));

  // Likes --------------------------------------------------------------------------------------

  Stream<bool> watchIsLiked(String videoId) =>
      (_db.select(_db.likedSongs)..where((t) => t.videoId.equals(videoId))).watch().map((r) => r.isNotEmpty);

  Future<void> setLiked(SongItem song, bool liked) async {
    if (liked) {
      await _upsertSong(song);
      await _db
          .into(_db.likedSongs)
          .insertOnConflictUpdate(LikedSongsCompanion.insert(videoId: song.videoId, likedAt: DateTime.now()));
    } else {
      await (_db.delete(_db.likedSongs)..where((t) => t.videoId.equals(song.videoId))).go();
    }
  }

  Stream<List<SongItem>> watchLikedSongs() {
    final q = _db.select(_db.likedSongs).join([
      innerJoin(_db.songs, _db.songs.videoId.equalsExp(_db.likedSongs.videoId)),
    ])..orderBy([OrderingTerm.desc(_db.likedSongs.likedAt)]);
    return q.watch().map((rows) => rows.map((r) => songFromRow(r.readTable(_db.songs))).toList());
  }

  // History ------------------------------------------------------------------------------------

  Future<void> addToHistory(SongItem song) async {
    await _upsertSong(song);
    await _db
        .into(_db.playHistory)
        .insert(PlayHistoryCompanion.insert(videoId: song.videoId, playedAt: DateTime.now()));
  }

  /// Most recent plays, one entry per song.
  Stream<List<SongItem>> watchHistory({int limit = 200}) {
    final latest = _db.playHistory.playedAt.max();
    final q = _db.selectOnly(_db.playHistory)
      ..addColumns([_db.playHistory.videoId, latest])
      ..groupBy([_db.playHistory.videoId])
      ..orderBy([OrderingTerm.desc(latest)])
      ..limit(limit);
    return q.watch().asyncMap((rows) async {
      final ids = rows.map((r) => r.read(_db.playHistory.videoId)!).toList();
      final songs = await (_db.select(_db.songs)..where((t) => t.videoId.isIn(ids))).get();
      final byId = {for (final s in songs) s.videoId: songFromRow(s)};
      return [for (final id in ids) ?byId[id]];
    });
  }

  Future<void> clearHistory() => _db.delete(_db.playHistory).go();

  // Saved albums / artists / playlists ----------------------------------------------------------

  Stream<bool> watchIsSaved(YTItem item) => switch (item) {
    AlbumItem() => (_db.select(
      _db.savedAlbums,
    )..where((t) => t.browseId.equals(item.browseId))).watch().map((r) => r.isNotEmpty),
    ArtistItem() => (_db.select(
      _db.savedArtists,
    )..where((t) => t.browseId.equals(item.browseId))).watch().map((r) => r.isNotEmpty),
    PlaylistItem() => (_db.select(
      _db.savedPlaylists,
    )..where((t) => t.playlistId.equals(item.id))).watch().map((r) => r.isNotEmpty),
    SongItem() => watchIsLiked(item.videoId),
  };

  Future<void> setSaved(YTItem item, bool saved) async {
    final now = DateTime.now();
    switch (item) {
      case AlbumItem():
        saved
            ? await _db
                  .into(_db.savedAlbums)
                  .insertOnConflictUpdate(
                    SavedAlbumsCompanion.insert(
                      browseId: item.browseId,
                      playlistId: Value(item.playlistId),
                      title: item.title,
                      artistsJson: Value(encodeArtists(item.artists)),
                      year: Value(item.year),
                      thumbnailUrl: Value(item.thumbnails.best(544)),
                      savedAt: now,
                    ),
                  )
            : await (_db.delete(_db.savedAlbums)..where((t) => t.browseId.equals(item.browseId))).go();
      case ArtistItem():
        saved
            ? await _db
                  .into(_db.savedArtists)
                  .insertOnConflictUpdate(
                    SavedArtistsCompanion.insert(
                      browseId: item.browseId,
                      title: item.title,
                      thumbnailUrl: Value(item.thumbnails.best(544)),
                      savedAt: now,
                    ),
                  )
            : await (_db.delete(_db.savedArtists)..where((t) => t.browseId.equals(item.browseId))).go();
      case PlaylistItem():
        saved
            ? await _db
                  .into(_db.savedPlaylists)
                  .insertOnConflictUpdate(
                    SavedPlaylistsCompanion.insert(
                      playlistId: item.id,
                      title: item.title,
                      author: Value(item.author?.name),
                      thumbnailUrl: Value(item.thumbnails.best(544)),
                      savedAt: now,
                    ),
                  )
            : await (_db.delete(_db.savedPlaylists)..where((t) => t.playlistId.equals(item.id))).go();
      case SongItem():
        await setLiked(item, saved);
    }
  }

  static List<Thumbnail> _thumb(String? url) => [if (url != null) Thumbnail(url: url, width: 544, height: 544)];

  Stream<List<AlbumItem>> watchSavedAlbums() =>
      (_db.select(_db.savedAlbums)..orderBy([(t) => OrderingTerm.desc(t.savedAt)])).watch().map(
        (rows) => [
          for (final r in rows)
            AlbumItem(
              browseId: r.browseId,
              playlistId: r.playlistId,
              title: r.title,
              artists: decodeArtists(r.artistsJson),
              year: r.year,
              thumbnails: _thumb(r.thumbnailUrl),
              subtitle: [decodeArtists(r.artistsJson).map((a) => a.name).join(', '), ?r.year].join(' • '),
            ),
        ],
      );

  Stream<List<ArtistItem>> watchSavedArtists() =>
      (_db.select(_db.savedArtists)..orderBy([(t) => OrderingTerm.desc(t.savedAt)])).watch().map(
        (rows) => [
          for (final r in rows)
            ArtistItem(browseId: r.browseId, title: r.title, thumbnails: _thumb(r.thumbnailUrl), subtitle: 'Artist'),
        ],
      );

  Stream<List<PlaylistItem>> watchSavedPlaylists() =>
      (_db.select(_db.savedPlaylists)..orderBy([(t) => OrderingTerm.desc(t.savedAt)])).watch().map(
        (rows) => [
          for (final r in rows)
            PlaylistItem(
              id: r.playlistId,
              title: r.title,
              author: r.author == null ? null : ArtistRef(name: r.author!),
              thumbnails: _thumb(r.thumbnailUrl),
              subtitle: ['Playlist', ?r.author].join(' • '),
            ),
        ],
      );

  // Local playlists ----------------------------------------------------------------------------

  Future<int> createPlaylist(String name) =>
      _db.into(_db.localPlaylists).insert(LocalPlaylistsCompanion.insert(name: name, createdAt: DateTime.now()));

  Future<void> renamePlaylist(int id, String name) =>
      (_db.update(_db.localPlaylists)..where((t) => t.id.equals(id))).write(LocalPlaylistsCompanion(name: Value(name)));

  Future<void> deletePlaylist(int id) => (_db.delete(_db.localPlaylists)..where((t) => t.id.equals(id))).go();

  Future<void> addToPlaylist(int playlistId, List<SongItem> songs) => _db.transaction(() async {
    final maxPos = _db.localPlaylistItems.position.max();
    final row =
        await (_db.selectOnly(_db.localPlaylistItems)
              ..addColumns([maxPos])
              ..where(_db.localPlaylistItems.playlistId.equals(playlistId)))
            .getSingle();
    var pos = (row.read(maxPos) ?? -1) + 1;
    for (final s in songs) {
      await _upsertSong(s);
      await _db
          .into(_db.localPlaylistItems)
          .insert(LocalPlaylistItemsCompanion.insert(playlistId: playlistId, videoId: s.videoId, position: pos++));
    }
  });

  Future<void> removeFromPlaylist(int itemId) =>
      (_db.delete(_db.localPlaylistItems)..where((t) => t.id.equals(itemId))).go();

  /// Moves the item at [from] to [to] and renumbers positions.
  Future<void> reorderPlaylist(int playlistId, int from, int to) => _db.transaction(() async {
    final items =
        await (_db.select(_db.localPlaylistItems)
              ..where((t) => t.playlistId.equals(playlistId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    final moved = items.removeAt(from);
    items.insert(to, moved);
    for (final (i, item) in items.indexed) {
      await (_db.update(
        _db.localPlaylistItems,
      )..where((t) => t.id.equals(item.id))).write(LocalPlaylistItemsCompanion(position: Value(i)));
    }
  });

  Stream<List<LocalPlaylistSummary>> watchLocalPlaylists() {
    final count = _db.localPlaylistItems.id.count();
    final q =
        _db.select(_db.localPlaylists).join([
            leftOuterJoin(_db.localPlaylistItems, _db.localPlaylistItems.playlistId.equalsExp(_db.localPlaylists.id)),
          ])
          ..addColumns([count])
          ..groupBy([_db.localPlaylists.id])
          ..orderBy([OrderingTerm.desc(_db.localPlaylists.createdAt)]);
    return q.watch().asyncMap(
      (rows) async => [
        for (final r in rows)
          LocalPlaylistSummary(
            id: r.readTable(_db.localPlaylists).id,
            name: r.readTable(_db.localPlaylists).name,
            songCount: r.read(count) ?? 0,
            thumbnailUrl: await _firstThumb(r.readTable(_db.localPlaylists).id),
          ),
      ],
    );
  }

  Future<String?> _firstThumb(int playlistId) async {
    final q =
        _db.select(_db.localPlaylistItems).join([
            innerJoin(_db.songs, _db.songs.videoId.equalsExp(_db.localPlaylistItems.videoId)),
          ])
          ..where(_db.localPlaylistItems.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(_db.localPlaylistItems.position)])
          ..limit(1);
    return (await q.getSingleOrNull())?.readTable(_db.songs).thumbnailUrl;
  }

  Stream<String?> watchLocalPlaylistName(int id) =>
      (_db.select(_db.localPlaylists)..where((t) => t.id.equals(id))).watchSingleOrNull().map((r) => r?.name);

  /// Songs with their row ids (needed for removing a specific occurrence).
  Stream<List<(int, SongItem)>> watchLocalPlaylistSongs(int id) {
    final q =
        _db.select(_db.localPlaylistItems).join([
            innerJoin(_db.songs, _db.songs.videoId.equalsExp(_db.localPlaylistItems.videoId)),
          ])
          ..where(_db.localPlaylistItems.playlistId.equals(id))
          ..orderBy([OrderingTerm.asc(_db.localPlaylistItems.position)]);
    return q.watch().map(
      (rows) => [for (final r in rows) (r.readTable(_db.localPlaylistItems).id, songFromRow(r.readTable(_db.songs)))],
    );
  }

  // Search history -----------------------------------------------------------------------------

  Future<void> addSearch(String query) => _db
      .into(_db.searchHistory)
      .insertOnConflictUpdate(SearchHistoryCompanion.insert(query: query.trim(), searchedAt: DateTime.now()));

  Future<void> removeSearch(String query) => (_db.delete(_db.searchHistory)..where((t) => t.query.equals(query))).go();

  Stream<List<String>> watchSearchHistory({int limit = 20}) =>
      (_db.select(_db.searchHistory)
            ..orderBy([(t) => OrderingTerm.desc(t.searchedAt)])
            ..limit(limit))
          .watch()
          .map((rows) => rows.map((r) => r.query).toList());
}
