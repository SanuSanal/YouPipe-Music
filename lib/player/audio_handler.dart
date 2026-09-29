import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/sponsorblock.dart';
import '../data/stream_resolver.dart';
import '../innertube/models.dart';

enum QueueRepeatMode { off, all, one }

@immutable
class SleepTimer {
  const SleepTimer({this.endsAt, this.endOfSong = false});

  final DateTime? endsAt;
  final bool endOfSong;
}

/// Path of a downloaded copy of a song, or null.
typedef LocalFileLookup = Future<String?> Function(String videoId);

/// Returns the parts of a video to skip (SponsorBlock), or an empty list.
typedef SegmentLoader = Future<List<SkipSegment>> Function(String videoId);

/// Loads more songs for an endless queue (radio). Returns an empty list when exhausted.
typedef QueueExtender = Future<List<SongItem>> Function();

@immutable
class QueueState {
  const QueueState({
    this.songs = const [],
    this.index = -1,
    this.shuffle = false,
    this.repeat = QueueRepeatMode.off,
    this.title,
  });

  final List<SongItem> songs;
  final int index;
  final bool shuffle;
  final QueueRepeatMode repeat;

  /// e.g. "Radio" or the playlist the queue came from.
  final String? title;

  SongItem? get current => index >= 0 && index < songs.length ? songs[index] : null;

  QueueState copyWith({List<SongItem>? songs, int? index, bool? shuffle, QueueRepeatMode? repeat, String? title}) =>
      QueueState(
        songs: songs ?? this.songs,
        index: index ?? this.index,
        shuffle: shuffle ?? this.shuffle,
        repeat: repeat ?? this.repeat,
        title: title ?? this.title,
      );
}

/// Background playback: just_audio behind audio_service (notification, lockscreen, headset keys).
///
/// Stream URLs are resolved lazily per track because they expire and are IP-bound.
class YouPipeAudioHandler extends BaseAudioHandler with SeekHandler {
  YouPipeAudioHandler(this._resolver) {
    _player.playbackEventStream.listen(_broadcastState, onError: _onPlayerError);
    _player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) _onCompleted();
    });
    _player.positionStream.listen(_skipSegments);
    _initSession();
  }

  final StreamResolver _resolver;

  /// Android audio effects, configured from the Equalizer sheet.
  final equalizer = AndroidEqualizer();
  final loudness = AndroidLoudnessEnhancer();
  late final _player = AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [loudness, equalizer]));

  /// Offline copies are played instead of streaming when available.
  LocalFileLookup? localFile;

  /// Set by the app when SponsorBlock is enabled; null disables skipping.
  SegmentLoader? segmentLoader;
  List<SkipSegment> _segments = const [];

  /// Emits when a non-music section was skipped (for a toast).
  final skippedSegments = StreamController<SkipSegment>.broadcast();

  /// When playback will stop, if a sleep timer is set.
  final sleepTimer = ValueNotifier<SleepTimer?>(null);
  Timer? _sleepTimer;

  /// The queue as rich song models (audio_service's `queue` only carries MediaItems).
  final queueState = ValueNotifier(const QueueState());

  QueueExtender? _extender;
  bool _extending = false;

  /// Guards against a stale load finishing after the user already picked another track.
  int _loadGeneration = 0;
  bool _retriedCurrent = false;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.becomingNoisyEventStream.listen((_) => pause());
  }

  static MediaItem toMediaItem(SongItem s) => MediaItem(
    id: s.videoId,
    title: s.title,
    artist: s.artistNames,
    album: s.album?.name,
    duration: s.duration,
    artUri: switch (s.thumbnails.best(544)) {
      final url? when url.startsWith('/') => Uri.file(url),
      final url? => Uri.parse(url),
      null => null,
    },
  );

  void _publish(QueueState state) {
    queueState.value = state;
    queue.add(state.songs.map(toMediaItem).toList());
  }

  // Queue building ---------------------------------------------------------------------------

  /// Replaces the queue with [songs] and starts at [startIndex].
  /// [extender] keeps the queue going when it runs out (radio / autoplay).
  Future<void> playSongs(
    List<SongItem> songs, {
    int startIndex = 0,
    String? title,
    QueueExtender? extender,
    bool shuffle = false,
  }) async {
    if (songs.isEmpty) return;
    var list = List.of(songs);
    var start = startIndex.clamp(0, list.length - 1);
    if (shuffle) {
      final first = list.removeAt(start);
      list.shuffle(Random());
      list = [first, ...list];
      start = 0;
    }
    _extender = extender;
    _publish(QueueState(songs: list, index: start, shuffle: shuffle, repeat: queueState.value.repeat, title: title));
    await _loadIndex(start);
  }

  /// Inserts right after the current song.
  void playNext(List<SongItem> songs) {
    final s = queueState.value;
    if (s.current == null) {
      unawaited(playSongs(songs));
      return;
    }
    final list = List.of(s.songs)..insertAll(s.index + 1, songs);
    _publish(s.copyWith(songs: list));
  }

  void addToQueue(List<SongItem> songs) {
    final s = queueState.value;
    if (s.current == null) {
      unawaited(playSongs(songs));
      return;
    }
    _publish(s.copyWith(songs: [...s.songs, ...songs]));
  }

  void removeFromQueue(int i) {
    final s = queueState.value;
    if (i == s.index || i < 0 || i >= s.songs.length) return;
    final list = List.of(s.songs)..removeAt(i);
    _publish(s.copyWith(songs: list, index: i < s.index ? s.index - 1 : s.index));
  }

  void moveInQueue(int from, int to) {
    final s = queueState.value;
    if (from == to) return;
    final list = List.of(s.songs);
    final song = list.removeAt(from);
    list.insert(to, song);
    var index = s.index;
    if (from == s.index) {
      index = to;
    } else if (from < s.index && to >= s.index) {
      index--;
    } else if (from > s.index && to <= s.index) {
      index++;
    }
    _publish(s.copyWith(songs: list, index: index));
  }

  /// Like YouTube Music: shuffling reorders the upcoming songs in the visible queue.
  void toggleShuffle() {
    final s = queueState.value;
    if (!s.shuffle && s.current != null) {
      final upcoming = s.songs.sublist(s.index + 1)..shuffle(Random());
      _publish(s.copyWith(songs: [...s.songs.sublist(0, s.index + 1), ...upcoming], shuffle: true));
    } else {
      _publish(s.copyWith(shuffle: !s.shuffle));
    }
    _broadcastState(null);
  }

  void cycleRepeat() {
    final s = queueState.value;
    final next = QueueRepeatMode.values[(s.repeat.index + 1) % QueueRepeatMode.values.length];
    _publish(s.copyWith(repeat: next));
    _broadcastState(null);
  }

  // Playback ---------------------------------------------------------------------------------

  Future<void> _loadIndex(int index, {Duration? position, bool forceRefresh = false}) async {
    final s = queueState.value;
    if (index < 0 || index >= s.songs.length) return;
    final gen = ++_loadGeneration;
    if (!forceRefresh) _retriedCurrent = false;
    final song = s.songs[index];
    _publish(s.copyWith(index: index));
    mediaItem.add(toMediaItem(song));
    playbackState.add(
      playbackState.value.copyWith(
        queueIndex: index,
        processingState: AudioProcessingState.loading,
        updatePosition: Duration.zero,
      ),
    );
    unawaited(_maybeExtend());

    try {
      final local = await localFile?.call(song.videoId);
      if (gen != _loadGeneration) return;
      final AudioSource source;
      if (local != null) {
        source = AudioSource.file(local, tag: song.videoId);
      } else {
        final stream = await _resolver.resolve(song.videoId, forceRefresh: forceRefresh);
        if (gen != _loadGeneration) return;
        source = AudioSource.uri(Uri.parse(stream.url), tag: song.videoId);
      }
      final duration = await _player.setAudioSource(source, initialPosition: position);
      if (gen != _loadGeneration) return;
      if (duration != null) mediaItem.add(toMediaItem(song).copyWith(duration: duration));
      _segments = const [];
      final loader = segmentLoader;
      if (loader != null) {
        unawaited(
          loader(song.videoId).then((segs) {
            if (gen == _loadGeneration) _segments = segs;
          }, onError: (_) {}),
        );
      }
      _prefetchNext();
      await _player.play();
    } catch (e) {
      if (gen != _loadGeneration) return;
      debugPrint('YouPipe: failed to play ${song.videoId}: $e');
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorMessage: e is StreamResolveException ? e.message : '$e',
        ),
      );
    }
  }

  void _skipSegments(Duration position) {
    if (_segments.isEmpty || !_player.playing) return;
    for (final seg in _segments) {
      if (!seg.contains(position)) continue;
      skippedSegments.add(seg);
      final duration = _player.duration;
      // A segment running to the end means the song is over.
      if (duration != null && seg.end >= duration - const Duration(seconds: 1)) {
        _segments = const [];
        _onCompleted();
      } else {
        _player.seek(seg.end);
      }
      return;
    }
  }

  void _prefetchNext() {
    final s = queueState.value;
    if (s.index + 1 < s.songs.length) {
      unawaited(_resolver.resolve(s.songs[s.index + 1].videoId).then((_) {}, onError: (_) {}));
    }
  }

  /// Keeps radio queues topped up: fetch more when fewer than 5 songs remain.
  Future<void> _maybeExtend() async {
    final extender = _extender;
    final s = queueState.value;
    if (extender == null || _extending || s.songs.length - s.index > 5) return;
    _extending = true;
    try {
      final more = await extender();
      if (more.isEmpty) {
        _extender = null;
      } else {
        final known = queueState.value.songs.map((e) => e.videoId).toSet();
        addToQueue(more.where((m) => !known.contains(m.videoId)).toList());
      }
    } catch (e) {
      debugPrint('YouPipe: queue extension failed: $e');
    } finally {
      _extending = false;
    }
  }

  void _onCompleted() {
    if (sleepTimer.value?.endOfSong == true) {
      cancelSleepTimer();
      _player.pause();
      return;
    }
    final s = queueState.value;
    if (s.repeat == QueueRepeatMode.one) {
      _player.seek(Duration.zero);
      _player.play();
    } else if (s.index + 1 < s.songs.length) {
      _loadIndex(s.index + 1);
    } else if (s.repeat == QueueRepeatMode.all && s.songs.isNotEmpty) {
      _loadIndex(0);
    } else {
      _player.pause();
      _player.seek(Duration.zero);
    }
  }

  /// A 403 mid-song usually means the URL expired or got revoked: re-resolve once and resume.
  void _onPlayerError(Object error, StackTrace st) {
    debugPrint('YouPipe: player error $error');
    final s = queueState.value;
    if (s.current == null || _retriedCurrent) return;
    _retriedCurrent = true;
    _resolver.invalidate(s.current!.videoId);
    _loadIndex(s.index, position: _player.position, forceRefresh: true);
  }

  void _broadcastState(PlaybackEvent? _) {
    final playing = _player.playing;
    final s = queueState.value;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
        androidCompactActionIndices: const [0, 1, 2],
        processingState:
            playbackState.value.processingState == AudioProcessingState.error &&
                _player.processingState == ProcessingState.idle
            ? AudioProcessingState.error
            : const {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: s.index,
        shuffleMode: s.shuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
        repeatMode: switch (s.repeat) {
          QueueRepeatMode.off => AudioServiceRepeatMode.none,
          QueueRepeatMode.all => AudioServiceRepeatMode.all,
          QueueRepeatMode.one => AudioServiceRepeatMode.one,
        },
      ),
    );
  }

  @override
  Future<void> play() async {
    if (playbackState.value.processingState == AudioProcessingState.error) {
      return _loadIndex(queueState.value.index, position: _player.position, forceRefresh: true);
    }
    return _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) => _loadIndex(index);

  @override
  Future<void> skipToNext() async {
    final s = queueState.value;
    if (s.index + 1 < s.songs.length) {
      await _loadIndex(s.index + 1);
    } else if (s.repeat == QueueRepeatMode.all && s.songs.isNotEmpty) {
      await _loadIndex(0);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3) || queueState.value.index <= 0) {
      await _player.seek(Duration.zero);
    } else {
      await _loadIndex(queueState.value.index - 1);
    }
  }

  // Sleep timer, speed ---------------------------------------------------------------------

  Stream<double> get speedStream => _player.speedStream;
  double get speed => _player.speed;

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    _broadcastState(null);
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    sleepTimer.value = SleepTimer(endsAt: DateTime.now().add(duration));
    _sleepTimer = Timer(duration, _fadeOutAndPause);
  }

  void sleepAtEndOfSong() {
    _sleepTimer?.cancel();
    sleepTimer.value = const SleepTimer(endOfSong: true);
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimer.value = null;
  }

  Future<void> _fadeOutAndPause() async {
    const steps = 20;
    for (var i = steps; i >= 0; i--) {
      if (sleepTimer.value == null) break;
      await _player.setVolume(i / steps);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    await _player.pause();
    await _player.setVolume(1);
    cancelSleepTimer();
  }

  // Audio effects ------------------------------------------------------------------------------

  /// Re-applies saved equalizer settings; band gains are set once the effect is active.
  void restoreAudioEffects({required bool eqEnabled, required List<double> gains, required double loudnessDb}) {
    equalizer.setEnabled(eqEnabled);
    loudness.setEnabled(loudnessDb > 0);
    loudness.setTargetGain(loudnessDb);
    if (gains.isEmpty) return;
    unawaited(
      equalizer.parameters.then((p) async {
        for (final band in p.bands) {
          if (band.index < gains.length) await band.setGain(gains[band.index]);
        }
      }),
    );
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
}
