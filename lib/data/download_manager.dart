import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../innertube/models.dart';
import 'db/app_database.dart';
import 'error_log.dart';
import 'stream_resolver.dart';

/// A download row joined with its song.
class DownloadEntry {
  const DownloadEntry({required this.song, required this.row});

  final SongItem song;
  final Download row;

  double get progress => row.sizeBytes == 0 ? 0 : row.downloadedBytes / row.sizeBytes;
}

/// Saves songs for offline playback: audio via the native downloader (1 MB range requests),
/// plus cover art so the offline library still looks right.
class DownloadManager {
  DownloadManager(this._db, this._resolver, {Dio? dio})
    : _dio =
          dio ??
          Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 30)));

  static const _native = MethodChannel('youpipe/downloader');
  static const _progress = EventChannel('youpipe/downloader/progress');

  final AppDatabase _db;
  final StreamResolver _resolver;
  final Dio _dio;
  final _queue = Queue<SongItem>();
  bool _running = false;
  String? _currentId;
  CancelToken? _cancel;

  StreamSubscription<dynamic>? _progressSub;
  DateTime _lastProgressWrite = DateTime.fromMillisecondsSinceEpoch(0);

  /// Mirrors native progress into the database (throttled; the UI watches the table).
  void _listenProgress() {
    _progressSub ??= _progress.receiveBroadcastStream().listen((event) {
      final m = (event as Map).cast<String, Object?>();
      final now = DateTime.now();
      final downloaded = m['downloaded'] as int;
      final total = m['total'] as int;
      if (downloaded < total && now.difference(_lastProgressWrite) < const Duration(milliseconds: 400)) return;
      _lastProgressWrite = now;
      _update(m['id'] as String, DownloadsCompanion(downloadedBytes: Value(downloaded), sizeBytes: Value(total)));
    });
  }

  Future<Directory> _dir() async {
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/downloads');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Re-queues downloads interrupted by the app being closed.
  Future<void> resumePending() async {
    final rows =
        await (_db.select(_db.downloads)
              ..where((t) => t.status.isIn([DownloadStatus.queued.index, DownloadStatus.downloading.index])))
            .join([innerJoin(_db.songs, _db.songs.videoId.equalsExp(_db.downloads.videoId))])
            .get();
    for (final r in rows) {
      _queue.add(songFromRow(r.readTable(_db.songs)));
    }
    unawaited(_pump());
  }

  Future<void> enqueue(List<SongItem> songs) async {
    final existing = {
      for (final r in await (_db.select(
        _db.downloads,
      )..where((t) => t.videoId.isIn(songs.map((s) => s.videoId)))).get())
        r.videoId: r.status,
    };
    for (final song in songs) {
      final status = existing[song.videoId];
      if (status == DownloadStatus.done || status == DownloadStatus.queued || status == DownloadStatus.downloading) {
        continue;
      }
      await _db.into(_db.songs).insertOnConflictUpdate(songToCompanion(song));
      await _db
          .into(_db.downloads)
          .insertOnConflictUpdate(
            DownloadsCompanion.insert(videoId: song.videoId, status: DownloadStatus.queued, addedAt: DateTime.now()),
          );
      _queue.add(song);
    }
    unawaited(_pump());
  }

  Future<void> remove(String videoId) async {
    _queue.removeWhere((s) => s.videoId == videoId);
    if (_currentId == videoId) {
      _cancel?.cancel();
      await _native.invokeMethod<void>('cancel', {'id': videoId});
    }
    final row = await (_db.select(_db.downloads)..where((t) => t.videoId.equals(videoId))).getSingleOrNull();
    for (final path in [row?.filePath, row?.artPath]) {
      if (path != null) {
        final f = File(path);
        if (f.existsSync()) await f.delete();
      }
    }
    await (_db.delete(_db.downloads)..where((t) => t.videoId.equals(videoId))).go();
  }

  /// Local file for a finished download, or null.
  Future<String?> localPath(String videoId) async {
    final row = await (_db.select(
      _db.downloads,
    )..where((t) => t.videoId.equals(videoId) & t.status.equalsValue(DownloadStatus.done))).getSingleOrNull();
    final path = row?.filePath;
    return path != null && File(path).existsSync() ? path : null;
  }

  /// Video ids of finished downloads. Emits only when that set changes: progress writes (every
  /// 400 ms while downloading) and song upserts would otherwise rebuild every song row.
  Stream<Set<String>> watchDoneIds() {
    final q = _db.selectOnly(_db.downloads)
      ..addColumns([_db.downloads.videoId])
      ..where(_db.downloads.status.equalsValue(DownloadStatus.done));
    return q.watch().map((rows) => {for (final r in rows) r.read(_db.downloads.videoId)!}).distinct(setEquals);
  }

  Stream<List<DownloadEntry>> watchAll() {
    final q = _db.select(_db.downloads).join([innerJoin(_db.songs, _db.songs.videoId.equalsExp(_db.downloads.videoId))])
      ..orderBy([OrderingTerm.desc(_db.downloads.addedAt)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          () {
            final row = r.readTable(_db.downloads);
            final song = songFromRow(r.readTable(_db.songs));
            // Prefer the saved artwork so offline rows still have covers.
            return DownloadEntry(
              song: row.artPath == null
                  ? song
                  : song.copyWith(thumbnails: [Thumbnail(url: row.artPath!, width: 544, height: 544)]),
              row: row,
            );
          }(),
      ],
    );
  }

  Future<void> _update(String videoId, DownloadsCompanion c) =>
      (_db.update(_db.downloads)..where((t) => t.videoId.equals(videoId))).write(c);

  Future<void> _pump() async {
    if (_running) return;
    _running = true;
    _listenProgress();
    try {
      while (_queue.isNotEmpty) {
        final song = _queue.removeFirst();
        await _download(song);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _download(SongItem song) async {
    final id = song.videoId;
    _currentId = id;
    _cancel = CancelToken();
    final dir = await _dir();
    File? file;
    try {
      await _update(id, const DownloadsCompanion(status: Value(DownloadStatus.downloading)));
      final stream = await _resolver.resolve(id, forceRefresh: true);
      final ext = (stream.mimeType ?? '').contains('webm') ? 'webm' : 'm4a';
      file = File('${dir.path}/$id.$ext');
      // Native download: same network stack as extraction/playback (URLs are IP/client-bound).
      final offset = await _native.invokeMethod<int>('download', {'id': id, 'url': stream.url, 'path': file.path}) ?? 0;

      String? artPath;
      final artUrl = song.thumbnails.best(544);
      if (artUrl != null && artUrl.startsWith('http')) {
        try {
          artPath = '${dir.path}/$id.jpg';
          await _dio.download(artUrl, artPath, cancelToken: _cancel);
        } catch (_) {
          artPath = null;
        }
      }
      await _update(
        id,
        DownloadsCompanion(
          status: const Value(DownloadStatus.done),
          filePath: Value(file.path),
          artPath: Value(artPath),
          sizeBytes: Value(offset),
          downloadedBytes: Value(offset),
        ),
      );
    } catch (e) {
      if (file != null && file.existsSync()) await file.delete();
      if (e is DioException && CancelToken.isCancel(e)) return;
      if (e is PlatformException && e.code == 'CANCELLED') return;
      errorLog.add('download', e, detail: id);
      await _update(id, const DownloadsCompanion(status: Value(DownloadStatus.failed)));
    } finally {
      _currentId = null;
    }
  }

  Future<void> retry(SongItem song) async {
    await _update(song.videoId, const DownloadsCompanion(status: Value(DownloadStatus.queued)));
    _queue.add(song);
    unawaited(_pump());
  }
}
