import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/error_log.dart';
import '../data/sponsorblock.dart';
import '../data/stream_resolver.dart';
import '../innertube/models.dart';
import 'auto_browser.dart';
import 'cast.dart';
import 'video_output.dart';

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
    _player.playbackEventStream.listen(_broadcastState);
    // just_audio 0.10 reports player errors here, not as errors on playbackEventStream.
    _player.errorStream.listen(_onPlayerError);
    _player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) _onCompleted();
    });
    _player.currentIndexStream.listen(_onPlayerIndex);
    _player.positionStream.listen((p) {
      if (_output != null) return;
      _skipSegments(p);
      // The player resets its position when it fails; keep where the song was to resume there.
      if (p > Duration.zero && _player.processingState != ProcessingState.idle) _lastPosition = p;
      if (_retries > 0 && !_recovering && p > _retryFrom + const Duration(seconds: 20)) _retries = 0;
    });
    _remotePositions.stream.listen(_skipSegments);
    _initSession();
  }

  final StreamResolver _resolver;

  /// Android audio effects, configured from the Equalizer sheet.
  final equalizer = AndroidEqualizer();
  final loudness = AndroidLoudnessEnhancer();
  late final _player = AudioPlayer(
    audioPipeline: AudioPipeline(androidAudioEffects: [loudness, equalizer]),
    // Buffer minutes ahead rather than ExoPlayer's 50 s, so short losses of signal (tunnels,
    // driving) pass unnoticed. At ~160 kbps that's only a few MB.
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        minBufferDuration: Duration(minutes: 3),
        maxBufferDuration: Duration(minutes: 5),
      ),
    ),
  );

  /// Android Auto browse tree; set once the app's services exist.
  AutoBrowser? browser;

  /// Offline copies are played instead of streaming when available.
  LocalFileLookup? localFile;

  /// Set by the app when SponsorBlock is enabled; null disables skipping.
  SegmentLoader? segmentLoader;
  List<SkipSegment> _segments = const [];

  // Outputs other than the phone's audio player: a Cast device while casting (docs/cast.md), else
  // the on-screen video player in video mode (docs/playback.md). They share one routing: while one
  // is active, songs load on it and transport, position and completion follow it.
  RemotePlayback? _cast;
  VideoOutput? _video;
  StreamSubscription<RemotePlayer>? _castPlayer;
  StreamSubscription<RemotePlayer>? _videoPlayer;

  /// Where songs play now; null is the phone's own audio player.
  RemotePlayback? _output;

  /// Video mode (the full player's Song/Video toggle). Casting turns it off.
  final videoMode = ValueNotifier(false);

  /// Emits a song that has no music video, when video mode had to fall back to the song.
  final noVideo = StreamController<SongItem>.broadcast();

  /// The output's key for the loaded song; its status updates carry it.
  String? _remoteUrl;
  RemotePlayer? _remote;
  Duration _remotePosition = Duration.zero;
  final _remotePositions = StreamController<Duration>.broadcast();
  static const _castVolumeSteps = 20;

  /// Set by the app once the Cast channel exists.
  set cast(RemotePlayback? cast) {
    _cast?.status.removeListener(_onCastStatus);
    unawaited(_castPlayer?.cancel());
    _cast = cast;
    cast?.status.addListener(_onCastStatus);
    _castPlayer = cast?.player.listen(_onRemotePlayer);
    _onCastStatus();
  }

  /// Set by the app: the player behind video mode.
  set video(VideoOutput? video) {
    unawaited(_videoPlayer?.cancel());
    _video = video;
    _videoPlayer = video?.player.listen(_onRemotePlayer);
  }

  /// Turns video mode on or off; the song continues from the same position.
  void setVideoMode(bool on) {
    if (videoMode.value == on || (on && (casting || _video == null))) return;
    videoMode.value = on;
    _syncOutput();
  }

  bool get casting => _cast?.status.value.connected ?? false;

  bool get _remoteActive => _output != null;

  /// The lock screen player's Like button (`customAction('toggleLike')`); set by the app.
  Future<void> Function()? onToggleLike;
  String? _likedId;
  bool _liked = false;

  /// When playback will stop, if a sleep timer is set.
  final sleepTimer = ValueNotifier<SleepTimer?>(null);
  Timer? _sleepTimer;

  /// The queue as rich song models (audio_service's `queue` only carries MediaItems).
  final queueState = ValueNotifier(const QueueState());

  QueueExtender? _extender;
  bool _extending = false;

  /// Guards against a stale load finishing after the user already picked another track.
  int _loadGeneration = 0;

  // Recovering from a failed load or a player error (docs/playback.md): reload the song with a fresh
  // URL at the same position, then again with growing gaps while there's no network.
  static const _retryDelays = [
    Duration.zero,
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 30),
    Duration(seconds: 30),
    Duration(seconds: 30),
    Duration(seconds: 30),
    Duration(seconds: 30),
    Duration(seconds: 30),
  ];
  int _retries = 0;
  Timer? _retryTimer;
  bool _recovering = false;
  Duration _retryFrom = Duration.zero;

  /// Where the phone's player last was in the current song.
  Duration _lastPosition = Duration.zero;

  /// While [_loadIndex] waits for `setAudioSource`, whose failure its own catch handles.
  bool _settingSource = false;

  /// Serializes changes to the preloaded next song (see [_syncPreloaded]).
  Future<void> _preloadOp = Future.value();
  Timer? _preloadRetry;

  /// Follows the active output; `positionProvider` re-subscribes when that changes.
  Stream<Duration> get positionStream => _remoteActive ? _remotePositions.stream : _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Duration get position => _remoteActive ? _remotePosition : _player.position;
  Duration? get duration => _remoteActive ? (_remote?.duration ?? mediaItem.value?.duration) : _player.duration;
  bool get _isPlaying => _remoteActive ? (_remote?.playing ?? false) : _player.playing;

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

  /// The current song's media item, with the liked flag the lock screen player reads.
  MediaItem _nowPlaying(SongItem s) => toMediaItem(s).copyWith(extras: {'liked': _likedId == s.videoId && _liked});

  /// Publishes whether [videoId] is liked, for the lock screen player.
  void setLiked(String videoId, bool liked) {
    _likedId = videoId;
    _liked = liked;
    final item = mediaItem.value;
    if (item?.id == videoId) mediaItem.add(item!.copyWith(extras: {...?item.extras, 'liked': liked}));
  }

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
    _syncPreloaded();
  }

  void addToQueue(List<SongItem> songs) {
    final s = queueState.value;
    if (s.current == null) {
      unawaited(playSongs(songs));
      return;
    }
    _publish(s.copyWith(songs: [...s.songs, ...songs]));
    _syncPreloaded();
  }

  void removeFromQueue(int i) {
    final s = queueState.value;
    if (i == s.index || i < 0 || i >= s.songs.length) return;
    final list = List.of(s.songs)..removeAt(i);
    _publish(s.copyWith(songs: list, index: i < s.index ? s.index - 1 : s.index));
    _syncPreloaded();
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
    _syncPreloaded();
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
    _syncPreloaded();
  }

  void cycleRepeat() {
    final s = queueState.value;
    final next = QueueRepeatMode.values[(s.repeat.index + 1) % QueueRepeatMode.values.length];
    _publish(s.copyWith(repeat: next));
    _broadcastState(null);
    _syncPreloaded();
  }

  // Playback ---------------------------------------------------------------------------------

  /// Loads and plays the song at [index]. [retry] marks a reload by [_recover]; any other load
  /// cancels a pending recovery.
  Future<void> _loadIndex(
    int index, {
    Duration? position,
    bool forceRefresh = false,
    bool autoplay = true,
    bool retry = false,
  }) async {
    final s = queueState.value;
    if (index < 0 || index >= s.songs.length) return;
    final gen = ++_loadGeneration;
    if (!retry) {
      _retryTimer?.cancel();
      _retries = 0;
      _recovering = false;
    }
    _lastPosition = position ?? Duration.zero;
    final song = s.songs[index];
    _publish(s.copyWith(index: index));
    mediaItem.add(_nowPlaying(song));
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
      _loadSegments(song.videoId, gen);
      final loader = segmentLoader;
      if (_remoteActive) {
        _remoteUrl = null;
        _remote = null;
        _remotePosition = position ?? Duration.zero;
        final output = _output!;
        final String? url;
        try {
          url = await output.load(
            item: _nowPlaying(song),
            localPath: local,
            position: position ?? Duration.zero,
            autoplay: autoplay,
          );
        } on NoVideoException {
          if (gen != _loadGeneration || !identical(output, _video)) return;
          // No music video for this song: carry on with the song itself.
          noVideo.add(song);
          videoMode.value = false;
          _output = null;
          unawaited(_video?.release());
          await _loadIndex(index, position: position, autoplay: autoplay);
          return;
        }
        if (gen != _loadGeneration) return;
        _remoteUrl = url;
        final videoId = _video?.currentVideoId;
        if (identical(output, _video) && loader != null && videoId != null && videoId != song.videoId) {
          unawaited(
            loader(videoId).then((segs) {
              if (gen == _loadGeneration) _segments = segs;
            }, onError: (_) {}),
          );
        }
        return;
      }
      // The song is already preloaded behind the current one: move on to it without reloading.
      if (position == null && !forceRefresh && _isPreloaded(song.videoId)) {
        await _player.seekToNext();
        if (autoplay) unawaited(_player.play());
        return;
      }
      final AudioSource source;
      if (local != null) {
        source = AudioSource.file(local, tag: song.videoId);
      } else {
        final stream = await _resolver.resolve(song.videoId, forceRefresh: forceRefresh);
        if (gen != _loadGeneration) return;
        source = AudioSource.uri(Uri.parse(stream.url), tag: song.videoId);
      }
      _settingSource = true;
      final Duration? duration;
      try {
        duration = await _player.setAudioSource(source, initialPosition: position);
      } finally {
        _settingSource = false;
      }
      if (gen != _loadGeneration) return;
      _recovering = false;
      if (duration != null) mediaItem.add(_nowPlaying(song).copyWith(duration: duration));
      _syncPreloaded();
      if (autoplay) await _player.play();
    } catch (e, st) {
      if (gen != _loadGeneration || e is PlayerInterruptedException) return;
      errorLog.add(
        'play',
        e is StreamResolveException ? '${e.code}: ${e.message}' : e,
        detail: _describe(song.videoId),
        stack: e is StreamResolveException || e is PlayerException ? null : st,
      );
      if (!_remoteActive && autoplay && _canRetry(e)) {
        _recover(index, position ?? Duration.zero);
        return;
      }
      _showError(e is StreamResolveException ? e.message : '$e');
    }
  }

  /// Unavailable, age- or region-restricted songs won't play on a retry either.
  static bool _canRetry(Object e) =>
      e is! StreamResolveException || e.code == 'EXTRACTION_FAILED' || e.code == 'RECAPTCHA';

  void _showError(String message) {
    _recovering = false;
    playbackState.add(
      playbackState.value.copyWith(processingState: AudioProcessingState.error, playing: false, errorMessage: message),
    );
  }

  /// Reloads the song at [index] from [position] with a fresh URL: at once, then with growing gaps
  /// (up to a few minutes) while it keeps failing, e.g. while there's no signal.
  void _recover(int index, Duration position) {
    _retryTimer?.cancel();
    if (_retries >= _retryDelays.length) {
      errorLog.add('play', 'Gave up after ${_retryDelays.length} attempts', detail: _describe(_videoIdAt(index)));
      _showError("Can't play this song");
      return;
    }
    final delay = _retryDelays[_retries++];
    _recovering = true;
    _retryFrom = position;
    // Stream URLs are bound to the phone's IP address, which usually changes after a loss of signal,
    // so every cached URL may be stale now.
    _resolver.clearCache();
    _broadcastState(null);
    final gen = _loadGeneration;
    _retryTimer = Timer(delay, () {
      if (gen != _loadGeneration || !_recovering) return;
      unawaited(_loadIndex(index, position: position, forceRefresh: true, retry: true));
    });
  }

  String? _videoIdAt(int index) {
    final songs = queueState.value.songs;
    return index >= 0 && index < songs.length ? songs[index].videoId : null;
  }

  /// "videoId · title", for the error log.
  String? _describe(String? videoId) {
    if (videoId == null) return null;
    final song = queueState.value.songs.where((s) => s.videoId == videoId).firstOrNull;
    return song == null ? videoId : '$videoId · ${song.title}';
  }

  /// Whether [videoId] is the song preloaded behind the current one.
  bool _isPreloaded(String videoId) {
    final seq = _player.sequence;
    return !_remoteActive && (_player.currentIndex ?? 0) == 0 && seq.length > 1 && seq[1].tag == videoId;
  }

  void _skipSegments(Duration position) {
    if (_segments.isEmpty || !_isPlaying) return;
    for (final seg in _segments) {
      if (!seg.contains(position)) continue;
      final duration = this.duration;
      // A segment running to the end means the song is over.
      if (duration != null && seg.end >= duration - const Duration(seconds: 1)) {
        _segments = const [];
        _onCompleted();
      } else {
        seek(seg.end);
      }
      return;
    }
  }

  void _loadSegments(String videoId, int gen) {
    _segments = const [];
    final loader = segmentLoader;
    if (loader == null) return;
    unawaited(
      loader(videoId).then((segs) {
        if (gen == _loadGeneration) _segments = segs;
      }, onError: (_) {}),
    );
  }

  // Preloading the next song ------------------------------------------------------------------
  //
  // On the phone's own player the next song sits behind the current one in just_audio's playlist, so
  // ExoPlayer buffers it before the current song ends and moves on without a gap (docs/playback.md).

  /// The queue index that plays after the current song; null when playback stops or repeats there.
  int? _upcomingIndex() {
    final s = queueState.value;
    if (s.current == null || s.repeat == QueueRepeatMode.one || sleepTimer.value?.endOfSong == true) return null;
    if (s.index + 1 < s.songs.length) return s.index + 1;
    if (s.repeat == QueueRepeatMode.all && s.songs.length > 1) return 0;
    return null;
  }

  /// Makes the player's playlist [current song, upcoming song]. Call it after anything that changes
  /// which song comes next.
  void _syncPreloaded() {
    _preloadRetry?.cancel();
    _preloadOp = _preloadOp.then((_) => _doSyncPreloaded()).catchError((Object e) {
      final upcoming = _upcomingIndex();
      errorLog.add(
        'preload',
        e is StreamResolveException ? '${e.code}: ${e.message}' : e,
        detail: upcoming == null ? null : _describe(_videoIdAt(upcoming)),
      );
      // Try again later (e.g. once there's signal again); if the current song ends first,
      // _onCompleted loads the next one fresh.
      final gen = _loadGeneration;
      _preloadRetry = Timer(const Duration(seconds: 20), () {
        if (gen == _loadGeneration) _syncPreloaded();
      });
    });
  }

  Future<void> _doSyncPreloaded() async {
    if (_remoteActive) return;
    final gen = _loadGeneration;
    final current = queueState.value.current;
    final at = _player.currentIndex ?? 0;
    if (current == null || at >= _player.sequence.length || _player.sequence[at].tag != current.videoId) return;
    // Drop the song the player already moved on from.
    if (at > 0) await _player.removeAudioSourceRange(0, at);
    final upcoming = _upcomingIndex();
    final want = upcoming == null ? null : queueState.value.songs[upcoming].videoId;
    final length = _player.sequence.length;
    if (length == 2 && _player.sequence[1].tag == want) return;
    if (gen != _loadGeneration) return;
    if (length > 1) await _player.removeAudioSourceRange(1, length);
    if (want == null) return;
    final local = await localFile?.call(want);
    final AudioSource source;
    if (local != null) {
      source = AudioSource.file(local, tag: want);
    } else {
      source = AudioSource.uri(Uri.parse((await _resolver.resolve(want)).url), tag: want);
    }
    final upcomingNow = _upcomingIndex();
    if (gen != _loadGeneration ||
        _remoteActive ||
        _player.sequence.length != 1 ||
        upcomingNow == null ||
        queueState.value.songs[upcomingNow].videoId != want) {
      return;
    }
    await _player.addAudioSource(source);
  }

  /// The player moved on to the preloaded song, by itself or through [_loadIndex]'s shortcut.
  void _onPlayerIndex(int? i) {
    if (i == null || i == 0 || _remoteActive) return;
    final seq = _player.sequence;
    if (i >= seq.length) return;
    final id = seq[i].tag as String?;
    final s = queueState.value;
    final upcoming = _upcomingIndex();
    final index = s.current?.videoId == id
        ? s.index
        : upcoming != null && s.songs[upcoming].videoId == id
        ? upcoming
        : s.songs.indexWhere((song) => song.videoId == id);
    if (index < 0) return;
    final gen = ++_loadGeneration;
    _retryTimer?.cancel();
    _recovering = false;
    _lastPosition = Duration.zero;
    final song = s.songs[index];
    _publish(s.copyWith(index: index));
    mediaItem.add(_nowPlaying(song).copyWith(duration: _player.duration ?? song.duration));
    _loadSegments(song.videoId, gen);
    unawaited(_maybeExtend());
    _syncPreloaded();
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
      errorLog.add('radio', 'Loading more songs failed: $e');
    } finally {
      _extending = false;
    }
  }

  void _onCompleted() {
    if (sleepTimer.value?.endOfSong == true) {
      cancelSleepTimer();
      pause();
      return;
    }
    final s = queueState.value;
    if (s.repeat == QueueRepeatMode.one) {
      if (_remoteActive) {
        _loadIndex(s.index);
      } else {
        _player.seek(Duration.zero);
        _player.play();
      }
    } else if (s.index + 1 < s.songs.length) {
      _loadNext(s.index + 1);
    } else if (s.repeat == QueueRepeatMode.all && s.songs.isNotEmpty) {
      _loadNext(0);
    } else if (!_remoteActive) {
      _player.pause();
      _player.seek(Duration.zero);
    }
  }

  /// Moves on after the current song ended. Unless the song was preloaded (then the player moves on
  /// by itself, or [_loadIndex] uses it), load it with a fresh URL: preloading it may have failed.
  void _loadNext(int index) {
    final id = _videoIdAt(index);
    _loadIndex(index, forceRefresh: !_remoteActive && id != null && !_isPreloaded(id));
  }

  /// The phone's player failed while playing: lost network (after its own retries), or a URL that
  /// expired or no longer matches the phone's IP address. Recover from the same position.
  void _onPlayerError(PlayerException e) {
    // A failed setAudioSource is handled by _loadIndex's catch, which may have scheduled a retry already.
    if (_remoteActive || _settingSource || (_retryTimer?.isActive ?? false)) return;
    final s = queueState.value;
    final current = s.current;
    if (current == null) return;
    final seq = _player.sequence;
    final i = e.index;
    final failedId = i != null && i < seq.length ? seq[i].tag as String? : current.videoId;
    errorLog.add('player', '${e.code}: ${e.message}', detail: _describe(failedId));
    // The preloaded next song failed as the player reached it: carry on with that song.
    final upcoming = _upcomingIndex();
    if (failedId != current.videoId && upcoming != null && s.songs[upcoming].videoId == failedId) {
      _recover(upcoming, Duration.zero);
    } else {
      _recover(s.index, _lastPosition);
    }
  }

  void _broadcastState(PlaybackEvent? _) {
    // While recovering, show the song as still playing (buffering), so a paused look doesn't
    // suggest it stopped for good.
    final recovering = _recovering && !_remoteActive;
    final playing = _isPlaying || recovering;
    final remote = _remoteActive ? _remote : null;
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
        processingState: _remoteActive
            ? (remote?.processingState ?? playbackState.value.processingState)
            : recovering
            ? AudioProcessingState.buffering
            : playbackState.value.processingState == AudioProcessingState.error &&
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
        updatePosition: position,
        bufferedPosition: _remoteActive ? _remotePosition : _player.bufferedPosition,
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

  // Chromecast ----------------------------------------------------------------------------------

  void _onCastStatus() {
    final status = _cast?.status.value ?? const CastStatus();
    if (status.connected && status.volumeControl) {
      // Volume keys and the system volume panel control the receiver.
      androidPlaybackInfo.add(
        RemoteAndroidPlaybackInfo(
          volumeControlType: AndroidVolumeControlType.absolute,
          maxVolume: _castVolumeSteps,
          volume: (status.volume * _castVolumeSteps).round(),
        ),
      );
    } else if (androidPlaybackInfo.valueOrNull is! LocalAndroidPlaybackInfo) {
      androidPlaybackInfo.add(LocalAndroidPlaybackInfo());
    }
    if (status.connected) videoMode.value = false;
    _syncOutput();
  }

  /// Moves playback to the output that should be active now: the Cast device while casting, else
  /// the video player in video mode, else the phone. The song carries on from the same position.
  void _syncOutput() {
    final target = casting ? _cast : (videoMode.value ? _video : null);
    if (identical(target, _output)) return;
    final previous = _output;
    final position = this.position;
    final wasPlaying = _isPlaying;
    if (previous == null) {
      unawaited(_player.pause());
    } else {
      unawaited(previous.pause());
      if (identical(previous, _video)) unawaited(_video!.release());
    }
    _output = target;
    _remoteUrl = null;
    _remote = null;
    // When casting ends, stay paused on the phone (as YouTube Music does); other switches keep playing.
    final autoplay = wasPlaying && !(identical(previous, _cast) && target == null);
    final s = queueState.value;
    if (s.current != null) unawaited(_loadIndex(s.index, position: position, autoplay: autoplay));
    _broadcastState(null);
  }

  void _onRemotePlayer(RemotePlayer p) {
    if (_output == null || p.url == null || p.url != _remoteUrl) return;
    final wasFinished = _remote?.finished ?? false;
    _remote = p;
    _remotePosition = p.position;
    _remotePositions.add(p.position);
    final item = mediaItem.value;
    if (item != null && item.duration == null && p.duration != null) mediaItem.add(item.copyWith(duration: p.duration));
    _broadcastState(null);
    if (p.finished && !wasFinished) _onCompleted();
  }

  @override
  Future<void> androidSetRemoteVolume(int volumeIndex) async => _cast?.setVolume(volumeIndex / _castVolumeSteps);

  @override
  Future<void> androidAdjustRemoteVolume(AndroidVolumeDirection direction) async {
    final volume = _cast?.status.value.volume ?? 0;
    await _cast?.setVolume(volume + direction.index / _castVolumeSteps);
  }

  /// Buttons of the lock screen player (LockScreenActivity.kt) that have no standard session action.
  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'toggleLike':
        await onToggleLike?.call();
      case 'cycleRepeat':
        cycleRepeat();
    }
  }

  // Android Auto / media browser ------------------------------------------------------------

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId, [Map<String, dynamic>? options]) async =>
      await browser?.children(parentMediaId) ?? const [];

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async => browser?.play(mediaId);

  @override
  Future<List<MediaItem>> search(String query, [Map<String, dynamic>? extras]) async =>
      await browser?.search(query) ?? const [];

  @override
  Future<void> playFromSearch(String query, [Map<String, dynamic>? extras]) async => browser?.playFromSearch(query);

  @override
  Future<void> play() async {
    if (_remoteActive) {
      final remote = _remote;
      // Nothing playable on the receiver (finished, failed or not loaded yet): load the song again.
      if (remote == null || remote.state == RemoteState.idle) {
        return _loadIndex(queueState.value.index, position: remote?.finished == true ? Duration.zero : _remotePosition);
      }
      return _output!.play();
    }
    // After an error, or a player that failed and went idle, or while waiting to retry: load again
    // now, from where the song was.
    if (queueState.value.current != null &&
        (_recovering ||
            playbackState.value.processingState == AudioProcessingState.error ||
            _player.processingState == ProcessingState.idle)) {
      return _loadIndex(queueState.value.index, position: _lastPosition, forceRefresh: true);
    }
    return _player.play();
  }

  @override
  Future<void> pause() async {
    if (_remoteActive) return _output!.pause();
    if (_recovering) {
      _retryTimer?.cancel();
      _recovering = false;
      _broadcastState(null);
    }
    return _player.pause();
  }

  @override
  Future<void> seek(Duration position) {
    if (!_remoteActive) return _player.seek(position);
    _remotePosition = position;
    _remotePositions.add(position);
    return _output!.seek(position);
  }

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
    if (position > const Duration(seconds: 3) || queueState.value.index <= 0) {
      await seek(Duration.zero);
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
    _syncPreloaded();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    final endOfSong = sleepTimer.value?.endOfSong ?? false;
    sleepTimer.value = null;
    if (endOfSong) _syncPreloaded();
  }

  Future<void> _fadeOutAndPause() async {
    if (_remoteActive) {
      await pause();
      cancelSleepTimer();
      return;
    }
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
    _retryTimer?.cancel();
    _preloadRetry?.cancel();
    _recovering = false;
    if (_remoteActive) await _output?.pause();
    await _player.stop();
    await super.stop();
  }
}
