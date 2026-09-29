import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../innertube/models.dart';

part 'app_database.g.dart';

/// Song metadata cache so library views render offline.
class Songs extends Table {
  TextColumn get videoId => text()();
  TextColumn get title => text()();
  TextColumn get artistsJson => text().withDefault(const Constant('[]'))();
  TextColumn get albumId => text().nullable()();
  TextColumn get albumName => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  BoolColumn get isVideo => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {videoId};
}

class LikedSongs extends Table {
  TextColumn get videoId => text().references(Songs, #videoId)();
  DateTimeColumn get likedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {videoId};
}

class PlayHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get videoId => text().references(Songs, #videoId)();
  DateTimeColumn get playedAt => dateTime()();
}

class SavedAlbums extends Table {
  TextColumn get browseId => text()();
  TextColumn get playlistId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get artistsJson => text().withDefault(const Constant('[]'))();
  TextColumn get year => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {browseId};
}

class SavedArtists extends Table {
  TextColumn get browseId => text()();
  TextColumn get title => text()();
  TextColumn get thumbnailUrl => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {browseId};
}

/// YouTube playlists saved to the library.
class SavedPlaylists extends Table {
  TextColumn get playlistId => text()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {playlistId};
}

/// Playlists created in YouPipe.
class LocalPlaylists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class LocalPlaylistItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId => integer().references(LocalPlaylists, #id, onDelete: KeyAction.cascade)();
  TextColumn get videoId => text().references(Songs, #videoId)();
  IntColumn get position => integer()();
}

class SearchHistory extends Table {
  TextColumn get query => text()();
  DateTimeColumn get searchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {query};
}

@DriftDatabase(
  tables: [
    Songs,
    LikedSongs,
    PlayHistory,
    SavedAlbums,
    SavedArtists,
    SavedPlaylists,
    LocalPlaylists,
    LocalPlaylistItems,
    SearchHistory,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'youpipe'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'));
}

// ---------------------------------------------------------------------------------------------
// Conversions between rows and InnerTube models
// ---------------------------------------------------------------------------------------------

String encodeArtists(List<ArtistRef> artists) => jsonEncode([
  for (final a in artists) {'name': a.name, 'id': ?a.id},
]);

List<ArtistRef> decodeArtists(String json) => [
  for (final a in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
    ArtistRef(name: a['name'] as String, id: a['id'] as String?),
];

SongsCompanion songToCompanion(SongItem s) => SongsCompanion.insert(
  videoId: s.videoId,
  title: s.title,
  artistsJson: Value(encodeArtists(s.artists)),
  albumId: Value(s.album?.id),
  albumName: Value(s.album?.name),
  durationMs: Value(s.duration?.inMilliseconds),
  thumbnailUrl: Value(s.thumbnails.best(544)),
  isVideo: Value(s.isVideo),
);

SongItem songFromRow(Song row) {
  final artists = decodeArtists(row.artistsJson);
  final album = row.albumId != null ? AlbumRef(name: row.albumName ?? '', id: row.albumId!) : null;
  return SongItem(
    videoId: row.videoId,
    title: row.title,
    artists: artists,
    album: album,
    duration: row.durationMs == null ? null : Duration(milliseconds: row.durationMs!),
    thumbnails: [if (row.thumbnailUrl != null) Thumbnail(url: row.thumbnailUrl!, width: 544, height: 544)],
    isVideo: row.isVideo,
    subtitle: [artists.map((a) => a.name).join(', '), ?album?.name].join(' • '),
  );
}
