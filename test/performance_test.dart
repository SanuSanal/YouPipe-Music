import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/data/db/app_database.dart';
import 'package:youpipe_music/data/download_manager.dart';
import 'package:youpipe_music/data/library_repository.dart';
import 'package:youpipe_music/data/stream_resolver.dart';
import 'package:youpipe_music/innertube/models.dart';
import 'package:youpipe_music/providers.dart';

/// Guards for the fixes in docs/performance.md.
void main() {
  late AppDatabase db;

  SongItem song(String id) => SongItem(videoId: id, title: 'Song $id', artists: const []);

  // Drift delivers query streams asynchronously; give a write time to reach its watchers.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('play history cap', () {
    test('keeps only the newest plays', () async {
      final library = LibraryRepository(db, historyLimit: 5);
      for (final id in ['a', 'b', 'c', 'a', 'd', 'e', 'f', 'g']) {
        await library.addToHistory(song(id));
      }
      final rows = await (db.select(db.playHistory)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      expect(rows.map((r) => r.videoId), ['a', 'd', 'e', 'f', 'g']);
    });

    test('History still lists each remaining song once', () async {
      final library = LibraryRepository(db, historyLimit: 5);
      for (final id in ['a', 'b', 'c', 'a', 'd', 'e', 'f', 'a']) {
        await library.addToHistory(song(id));
      }
      final history = await library.watchHistory().first;
      // Plays left: d e f a (a twice); b and c were pruned.
      expect(history.map((s) => s.videoId).toSet(), {'a', 'd', 'e', 'f'});
      expect(history, hasLength(4));
    });

    test('defaults to 2000 plays', () {
      expect(LibraryRepository(db).historyLimit, LibraryRepository.defaultHistoryLimit);
      expect(LibraryRepository.defaultHistoryLimit, 2000);
    });
  });

  group('finished downloads', () {
    Future<void> addDownload(String id, DownloadStatus status) async {
      await db.into(db.songs).insertOnConflictUpdate(songToCompanion(song(id)));
      await db
          .into(db.downloads)
          .insertOnConflictUpdate(DownloadsCompanion.insert(videoId: id, status: status, addedAt: DateTime.now()));
    }

    Future<void> setDownload(String id, DownloadsCompanion change) =>
        (db.update(db.downloads)..where((t) => t.videoId.equals(id))).write(change);

    test('watchDoneIds ignores progress and emits when the set changes', () async {
      final manager = DownloadManager(db, StreamResolver());
      final emitted = <Set<String>>[];
      final sub = manager.watchDoneIds().listen(emitted.add);
      await addDownload('a', DownloadStatus.downloading);
      await settle();
      expect(emitted, [<String>{}]);

      for (var i = 1; i <= 5; i++) {
        await setDownload('a', DownloadsCompanion(downloadedBytes: Value(i * 1000), sizeBytes: const Value(5000)));
        await settle();
      }
      await db.into(db.songs).insertOnConflictUpdate(songToCompanion(song('a')));
      await settle();
      expect(emitted, [<String>{}], reason: 'progress writes and song upserts change nothing');

      await setDownload('a', const DownloadsCompanion(status: Value(DownloadStatus.done)));
      await settle();
      expect(emitted.last, {'a'});

      await (db.delete(db.downloads)..where((t) => t.videoId.equals('a'))).go();
      await settle();
      expect(emitted.last, <String>{});
      expect(emitted, hasLength(3));
      await sub.cancel();
    });

    test("a song row is only told about its own song's download", () async {
      final container = ProviderContainer(
        overrides: [downloadManagerProvider.overrideWithValue(DownloadManager(db, StreamResolver()))],
      );
      addTearDown(container.dispose);
      final changes = <bool>[];
      container.listen(downloadedIdsProvider.select((ids) => ids.contains('a')), (_, next) => changes.add(next));

      await addDownload('a', DownloadStatus.downloading);
      await addDownload('b', DownloadStatus.downloading);
      await settle();
      await setDownload('a', const DownloadsCompanion(downloadedBytes: Value(100), sizeBytes: Value(200)));
      await setDownload('b', const DownloadsCompanion(status: Value(DownloadStatus.done)));
      await settle();
      expect(changes, isEmpty, reason: "progress on 'a' and 'b' finishing don't concern row 'a'");

      await setDownload('a', const DownloadsCompanion(status: Value(DownloadStatus.done)));
      await settle();
      expect(changes, [true]);
    });
  });
}
