import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/account.dart';
import 'data/db/app_database.dart';
import 'data/download_manager.dart';
import 'data/lyrics/lyrics_service.dart';
import 'data/sponsorblock.dart';
import 'data/library_repository.dart';
import 'data/stream_resolver.dart';
import 'data/updater.dart';
import 'innertube/innertube.dart';
import 'player/audio_handler.dart';
import 'player/auto_browser.dart';
import 'player/cast.dart';
import 'player/video_output.dart';

// ---------------------------------------------------------------------------------------------
// Core services (created in main() and injected with overrides)
// ---------------------------------------------------------------------------------------------

final innerTubeProvider = Provider<InnerTube>((ref) => throw UnimplementedError('overridden in main'));
final streamResolverProvider = Provider<StreamResolver>((ref) => throw UnimplementedError('overridden in main'));
final audioHandlerProvider = Provider<YouPipeAudioHandler>((ref) => throw UnimplementedError('overridden in main'));
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('overridden in main'));
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('overridden in main'));

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final manager = DownloadManager(ref.watch(databaseProvider), ref.watch(streamResolverProvider));
  ref.read(audioHandlerProvider).localFile = manager.localPath;
  return manager;
});

final downloadsProvider = StreamProvider<List<DownloadEntry>>((ref) => ref.watch(downloadManagerProvider).watchAll());

final _doneIdsProvider = StreamProvider<Set<String>>((ref) => ref.watch(downloadManagerProvider).watchDoneIds());

/// Video ids of finished downloads (for the row indicator). Changes only when a download finishes
/// or is removed; watch it with `select` so a row rebuilds only for its own song (docs/performance.md).
final downloadedIdsProvider = Provider<Set<String>>((ref) => ref.watch(_doneIdsProvider).value ?? const {});

/// Download state of one song (null = not downloaded).
final downloadStatusProvider = Provider.autoDispose.family<DownloadStatus?, String>(
  (ref, videoId) => ref.watch(
    downloadsProvider.select(
      (all) => (all.value ?? const <DownloadEntry>[]).where((d) => d.song.videoId == videoId).firstOrNull?.row.status,
    ),
  ),
);

/// Hooks the Android Auto browse tree into the audio handler (watched from the app root).
final autoBrowserProvider = Provider<AutoBrowser>((ref) {
  final actions = ref.watch(playerActionsProvider);
  final browser = AutoBrowser(
    yt: ref.watch(innerTubeProvider),
    library: ref.watch(libraryProvider),
    downloads: ref.watch(downloadManagerProvider),
    playSong: actions.playSong,
    playList: (songs, index, title) => actions.playList(songs, index: index, title: title),
  );
  ref.read(audioHandlerProvider).browser = browser;
  return browser;
});

/// Wires the lock screen player's Like button to the library and keeps its liked state current
/// (watched from the app root).
final lockScreenLikeProvider = Provider<void>((ref) {
  final handler = ref.read(audioHandlerProvider);
  final song = ref.watch(currentSongProvider);
  if (song == null) {
    handler.onToggleLike = null;
    return;
  }
  final liked = ref.watch(isLikedProvider(song.videoId)).value ?? false;
  handler.setLiked(song.videoId, liked);
  final account = ref.read(accountActionsProvider);
  handler.onToggleLike = () => account.setLiked(song, !liked);
});

final sponsorBlockProvider = Provider<SponsorBlockService>((ref) => SponsorBlockService());

final libraryProvider = Provider<LibraryRepository>((ref) => LibraryRepository(ref.watch(databaseProvider)));

// ---------------------------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------------------------

@immutable
class AppSettings {
  const AppSettings({
    this.quality = AudioQuality.high,
    this.videoQuality = VideoQuality.auto,
    this.hl = 'en',
    this.gl = 'US',
    this.saveHistory = true,
    this.skipNonMusic = true,
    this.autoUpdateCheck = true,
    this.lockScreenPlayer = false,
  });

  final AudioQuality quality;
  final VideoQuality videoQuality;
  final String hl;
  final String gl;
  final bool saveHistory;

  /// SponsorBlock: skip non-music sections of music videos.
  final bool skipNonMusic;

  /// Look for a new GitHub release when the app opens.
  final bool autoUpdateCheck;

  /// Show the full-screen lock screen player while music plays (read natively by LockScreenLauncher.kt).
  final bool lockScreenPlayer;

  AppSettings copyWith({
    AudioQuality? quality,
    VideoQuality? videoQuality,
    String? hl,
    String? gl,
    bool? saveHistory,
    bool? skipNonMusic,
    bool? autoUpdateCheck,
    bool? lockScreenPlayer,
  }) => AppSettings(
    quality: quality ?? this.quality,
    videoQuality: videoQuality ?? this.videoQuality,
    hl: hl ?? this.hl,
    gl: gl ?? this.gl,
    saveHistory: saveHistory ?? this.saveHistory,
    skipNonMusic: skipNonMusic ?? this.skipNonMusic,
    autoUpdateCheck: autoUpdateCheck ?? this.autoUpdateCheck,
    lockScreenPlayer: lockScreenPlayer ?? this.lockScreenPlayer,
  );
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  AppSettings build() {
    final p = ref.watch(prefsProvider);
    final s = AppSettings(
      quality: AudioQuality.values.asNameMap()[p.getString('quality')] ?? AudioQuality.high,
      videoQuality: VideoQuality.values.asNameMap()[p.getString('videoQuality')] ?? VideoQuality.auto,
      hl: p.getString('hl') ?? 'en',
      gl: p.getString('gl') ?? 'US',
      saveHistory: p.getBool('saveHistory') ?? true,
      skipNonMusic: p.getBool('skipNonMusic') ?? true,
      autoUpdateCheck: p.getBool('autoUpdateCheck') ?? true,
      lockScreenPlayer: p.getBool('lockScreenPlayer') ?? false,
    );
    _apply(s);
    return s;
  }

  void _apply(AppSettings s) {
    ref.read(innerTubeProvider)
      ..hl = s.hl
      ..gl = s.gl;
    ref.read(streamResolverProvider)
      ..hl = s.hl
      ..gl = s.gl
      ..quality = s.quality;
    final sponsorBlock = ref.read(sponsorBlockProvider);
    ref.read(audioHandlerProvider).segmentLoader = s.skipNonMusic ? sponsorBlock.segmentsFor : null;
  }

  Future<void> update(AppSettings s) async {
    state = s;
    _apply(s);
    await _prefs.setString('quality', s.quality.name);
    await _prefs.setString('videoQuality', s.videoQuality.name);
    await _prefs.setString('hl', s.hl);
    await _prefs.setString('gl', s.gl);
    await _prefs.setBool('saveHistory', s.saveHistory);
    await _prefs.setBool('skipNonMusic', s.skipNonMusic);
    await _prefs.setBool('autoUpdateCheck', s.autoUpdateCheck);
    await _prefs.setBool('lockScreenPlayer', s.lockScreenPlayer);
  }
}

// ---------------------------------------------------------------------------------------------
// In-app updates from GitHub Releases (docs/updates.md)
// ---------------------------------------------------------------------------------------------

final updaterProvider = Provider<Updater>((ref) => Updater());

final appInfoProvider = FutureProvider<AppInfo>((ref) => ref.watch(updaterProvider).appInfo());

sealed class UpdateState {
  const UpdateState();
}

class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable(this.update);

  final AvailableUpdate update;
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading(this.update, {this.received = 0, this.total = 0});

  final AvailableUpdate update;
  final int received;
  final int total;

  double? get progress => total > 0 ? received / total : null;
}

class UpdateInstalling extends UpdateState {
  const UpdateInstalling(this.update);

  final AvailableUpdate update;
}

class UpdateFailed extends UpdateState {
  const UpdateFailed(this.error, {this.update});

  final UpdateException error;

  /// The update being fetched or installed, so the sheet can offer a retry.
  final AvailableUpdate? update;
}

final updateProvider = NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

class UpdateController extends Notifier<UpdateState> {
  CancelToken? _cancel;

  Updater get _updater => ref.read(updaterProvider);
  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  UpdateState build() => const UpdateIdle();

  bool get busy => state is UpdateChecking || state is UpdateDownloading || state is UpdateInstalling;

  /// The launch check: silent on errors, and skipped in debug builds (they report pubspec's version and are
  /// signed with a different key), when turned off, or when the user skipped this version.
  Future<AvailableUpdate?> checkOnLaunch() async {
    await _updater.cleanup().catchError((_) {});
    if (kDebugMode || !ref.read(settingsProvider).autoUpdateCheck || busy) return null;
    try {
      final update = await _updater.check();
      if (update == null || update.version == _prefs.getString('skippedUpdateVersion')) return null;
      state = UpdateAvailable(update);
      return update;
    } on Object {
      return null;
    }
  }

  /// A check the user asked for. Returns the update, or null when up to date; throws [UpdateException].
  Future<AvailableUpdate?> checkNow() async {
    if (busy) {
      return switch (state) {
        UpdateDownloading(:final update) || UpdateInstalling(:final update) => update,
        _ => null,
      };
    }
    state = const UpdateChecking();
    try {
      final update = await _updater.check();
      state = update == null ? const UpdateIdle() : UpdateAvailable(update);
      return update;
    } on UpdateException {
      state = const UpdateIdle();
      rethrow;
    } on Object catch (e) {
      state = const UpdateIdle();
      throw UpdateException('NETWORK', e.toString());
    }
  }

  Future<void> skip(AvailableUpdate update) async {
    await _prefs.setString('skippedUpdateVersion', update.version);
    state = const UpdateIdle();
  }

  /// Downloads, verifies and installs [update]. Errors end up in [UpdateFailed].
  Future<void> downloadAndInstall(AvailableUpdate update) async {
    if (state is UpdateDownloading || state is UpdateInstalling) return;
    final cancel = _cancel = CancelToken();
    state = UpdateDownloading(update);
    try {
      final path = await _updater.download(
        update,
        cancelToken: cancel,
        onProgress: (received, total) => state = UpdateDownloading(update, received: received, total: total),
      );
      state = UpdateInstalling(update);
      await _updater.install(path);
      state = const UpdateIdle();
    } on UpdateException catch (e) {
      state = e.code == 'CANCELLED' ? UpdateAvailable(update) : UpdateFailed(e, update: update);
    } on Object catch (e) {
      state = UpdateFailed(UpdateException('INSTALL_FAILED', e.toString()), update: update);
    } finally {
      if (identical(_cancel, cancel)) _cancel = null;
    }
  }

  void cancelDownload() => _cancel?.cancel();
}

// ---------------------------------------------------------------------------------------------
// Audio effects (equalizer, loudness), persisted in prefs and applied to the audio handler
// ---------------------------------------------------------------------------------------------

@immutable
class AudioEffectsState {
  const AudioEffectsState({this.eqEnabled = false, this.gains = const [], this.loudnessDb = 0, this.preset = ''});

  final bool eqEnabled;
  final List<double> gains;

  /// Loudness boost in dB (0 = off).
  final double loudnessDb;
  final String preset;
}

final audioEffectsProvider = NotifierProvider<AudioEffectsController, AudioEffectsState>(AudioEffectsController.new);

class AudioEffectsController extends Notifier<AudioEffectsState> {
  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  AudioEffectsState build() {
    final p = ref.watch(prefsProvider);
    final s = AudioEffectsState(
      eqEnabled: p.getBool('eqEnabled') ?? false,
      gains: (p.getStringList('eqGains') ?? const []).map(double.parse).toList(),
      loudnessDb: p.getDouble('loudnessDb') ?? 0,
      preset: p.getString('eqPreset') ?? '',
    );
    ref
        .read(audioHandlerProvider)
        .restoreAudioEffects(eqEnabled: s.eqEnabled, gains: s.gains, loudnessDb: s.loudnessDb);
    return s;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AudioEffectsState(
      eqEnabled: enabled,
      gains: state.gains,
      loudnessDb: state.loudnessDb,
      preset: state.preset,
    );
    await ref.read(audioHandlerProvider).effects.setEqEnabled(enabled);
    await _prefs.setBool('eqEnabled', enabled);
  }

  /// Sets and saves the band gains (dB, by band index).
  Future<void> setGains(List<double> gains, {String preset = 'Custom'}) async {
    state = AudioEffectsState(eqEnabled: state.eqEnabled, gains: gains, loudnessDb: state.loudnessDb, preset: preset);
    await ref.read(audioHandlerProvider).effects.setGains(gains);
    await _prefs.setStringList('eqGains', gains.map((g) => g.toStringAsFixed(2)).toList());
    await _prefs.setString('eqPreset', preset);
  }

  /// Changes one band while its slider is dragged; [setGains] saves when the drag ends.
  Future<void> setBandGain(int band, double db, {required int bands}) async {
    final gains = [for (var i = 0; i < bands; i++) i == band ? db : (i < state.gains.length ? state.gains[i] : 0.0)];
    state = AudioEffectsState(eqEnabled: state.eqEnabled, gains: gains, loudnessDb: state.loudnessDb, preset: 'Custom');
    await ref.read(audioHandlerProvider).effects.setGains(gains);
  }

  Future<void> setLoudness(double db) async {
    state = AudioEffectsState(eqEnabled: state.eqEnabled, gains: state.gains, loudnessDb: db, preset: state.preset);
    await ref.read(audioHandlerProvider).effects.setLoudness(db);
    await _prefs.setDouble('loudnessDb', db);
  }
}

// ---------------------------------------------------------------------------------------------
// Player
// ---------------------------------------------------------------------------------------------

final sleepTimerProvider = StreamProvider<SleepTimer?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  final controller = StreamController<SleepTimer?>();
  void emit() => controller.add(handler.sleepTimer.value);
  handler.sleepTimer.addListener(emit);
  emit();
  ref.onDispose(() {
    handler.sleepTimer.removeListener(emit);
    controller.close();
  });
  return controller.stream;
});

final speedProvider = StreamProvider<double>((ref) => ref.watch(audioHandlerProvider).speedStream);

final queueStateProvider = StreamProvider<QueueState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  final controller = StreamController<QueueState>();
  void emit() => controller.add(handler.queueState.value);
  handler.queueState.addListener(emit);
  emit();
  ref.onDispose(() {
    handler.queueState.removeListener(emit);
    controller.close();
  });
  return controller.stream;
});

final playbackStateProvider = StreamProvider<PlaybackState>((ref) => ref.watch(audioHandlerProvider).playbackState);

final currentSongProvider = Provider<SongItem?>((ref) => ref.watch(queueStateProvider).value?.current);

final positionProvider = StreamProvider<Duration>((ref) {
  // The handler follows the receiver while casting: re-subscribe when that switches.
  ref.watch(castStatusProvider.select((s) => s.connected));
  ref.watch(videoModeProvider);
  return ref.watch(audioHandlerProvider).positionStream;
});

/// Chromecast (docs/cast.md). Watched from the app root, so the handler gets it at startup.
final castControllerProvider = Provider<CastController>((ref) {
  final cast = CastController();
  ref.read(audioHandlerProvider).cast = cast;
  return cast;
});

// Video mode (docs/playback.md) ------------------------------------------------------------------

/// Finds a song's music video once and remembers the answer (it's a search per song).
class MusicVideoFinder {
  MusicVideoFinder(this._yt);

  final InnerTube _yt;
  final _found = <String, String?>{};

  Future<String?> find(SongItem song) async {
    if (_found.containsKey(song.videoId)) return _found[song.videoId];
    try {
      return _found[song.videoId] = await _yt.musicVideoFor(song);
    } catch (e) {
      debugPrint('YouPipe: music video lookup failed: $e');
      return null;
    }
  }
}

final musicVideoFinderProvider = Provider<MusicVideoFinder>((ref) => MusicVideoFinder(ref.watch(innerTubeProvider)));

/// The music video id for the current song, if it has one (enables the Video toggle).
final musicVideoProvider = FutureProvider.autoDispose.family<String?, String>((ref, videoId) async {
  final song = ref.watch(queueStateProvider).value?.songs.where((s) => s.videoId == videoId).firstOrNull;
  return song == null ? null : ref.read(musicVideoFinderProvider).find(song);
});

/// Watched from the app root, so the handler gets its video output at startup.
final videoOutputProvider = Provider<VideoOutput>((ref) {
  final handler = ref.read(audioHandlerProvider);
  final finder = ref.read(musicVideoFinderProvider);
  final video = VideoOutput(
    findVideo: (item) async {
      final song = handler.queueState.value.songs.where((s) => s.videoId == item.id).firstOrNull;
      return song == null ? null : finder.find(song);
    },
    resolve: ref.read(streamResolverProvider).resolveVideo,
    resolveHd: ref.read(streamResolverProvider).resolveVideoManifest,
    quality: () => ref.read(settingsProvider).videoQuality,
  );
  handler.video = video;
  return video;
});

final videoModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(audioHandlerProvider).videoMode;
  void changed() => ref.invalidateSelf();
  mode.addListener(changed);
  ref.onDispose(() => mode.removeListener(changed));
  return mode.value;
});

final castStatusProvider = Provider<CastStatus>((ref) {
  final status = ref.watch(castControllerProvider).status;
  void changed() => ref.invalidateSelf();
  status.addListener(changed);
  ref.onDispose(() => status.removeListener(changed));
  return status.value;
});

final playerActionsProvider = Provider<PlayerActions>((ref) => PlayerActions(ref));

/// High-level "play this" actions that combine the audio handler with InnerTube (radio, queues).
class PlayerActions {
  PlayerActions(this._ref);

  final Ref _ref;

  YouPipeAudioHandler get _handler => _ref.read(audioHandlerProvider);
  InnerTube get _yt => _ref.read(innerTubeProvider);

  /// Endless queue from a watch endpoint's up-next panel.
  QueueExtender _radioExtender(WatchEndpoint endpoint, {bool skipFirst = false}) {
    String? continuation;
    String? playlistId = endpoint.playlistId;
    var first = true;
    return () async {
      final NextPage page;
      if (first) {
        page = await _yt.next(endpoint);
      } else if (continuation != null) {
        page = await _yt.nextContinuation(continuation!, playlistId: playlistId);
      } else {
        return const [];
      }
      continuation = page.continuation;
      playlistId = page.playlistId ?? playlistId;
      final items = first && skipFirst ? page.items.skip(1).toList() : page.items;
      first = false;
      return items;
    };
  }

  /// Tapping a single song: play it now, then keep going with its radio (like YouTube Music).
  Future<void> playSong(SongItem song) => _handler.playSongs(
    [song],
    title: 'Radio',
    extender: _radioExtender(
      WatchEndpoint(videoId: song.videoId, playlistId: 'RDAMVM${song.videoId}'),
      skipFirst: true,
    ),
  );

  Future<void> startRadio(SongItem song) => playSong(song);

  /// Play a known list (album, playlist, library) from [index].
  Future<void> playList(List<SongItem> songs, {int index = 0, bool shuffle = false, String? title}) =>
      _handler.playSongs(songs, startIndex: index, shuffle: shuffle, title: title);

  /// Artist shuffle/mix buttons and radio cards.
  Future<void> playEndpoint(WatchEndpoint endpoint, {String? title}) async {
    final extender = _radioExtender(endpoint);
    final first = await extender();
    await _handler.playSongs(first, title: title, extender: extender);
  }

  /// Plays a YouTube playlist (or album) by id without opening its page.
  Future<void> playPlaylistId(String playlistId, {bool shuffle = false, String? title}) async {
    final page = await _yt.playlist(playlistId);
    await playList(page.songs, shuffle: shuffle, title: title ?? page.playlist.title);
  }

  void playNext(List<SongItem> songs) => _handler.playNext(songs);
  void addToQueue(List<SongItem> songs) => _handler.addToQueue(songs);
}

// ---------------------------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------------------------

final albumProvider = FutureProvider.autoDispose.family<AlbumPage, String>(
  (ref, id) => ref.watch(innerTubeProvider).album(id),
);

final artistProvider = FutureProvider.autoDispose.family<ArtistPage, String>(
  (ref, id) => ref.watch(innerTubeProvider).artist(id),
);

final browseSectionsProvider = FutureProvider.autoDispose.family<SectionsPage, BrowseEndpoint>(
  (ref, ep) => ref.watch(innerTubeProvider).browseSections(ep),
);

final exploreProvider = FutureProvider<ExplorePage>((ref) async {
  await ref.watch(authProvider.future);
  return ref.watch(innerTubeProvider).explore();
});

final searchSuggestionsProvider = FutureProvider.autoDispose.family<SearchSuggestions, String>((ref, input) async {
  if (input.trim().isEmpty) return const SearchSuggestions(queries: [], items: []);
  // Debounce typing.
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(milliseconds: 250));
  if (cancelled) throw StateError('cancelled');
  return ref.watch(innerTubeProvider).searchSuggestions(input);
});

/// Watch-next info for a song; source of its lyrics and related browse ids.
final nextInfoProvider = FutureProvider.autoDispose.family<NextPage, String>(
  (ref, videoId) => ref.watch(innerTubeProvider).next(WatchEndpoint(videoId: videoId)),
);

final lyricsServiceProvider = Provider<LyricsService>((ref) => LyricsService(ref.watch(innerTubeProvider)));

/// Synced (LRCLIB) or plain (YouTube Music) lyrics for a song.
final songLyricsProvider = FutureProvider.autoDispose.family<SongLyrics?, SongItem>((ref, song) {
  final handler = ref.read(audioHandlerProvider);
  final duration = handler.queueState.value.current?.videoId == song.videoId ? handler.duration : null;
  return ref.watch(lyricsServiceProvider).lyricsFor(song, duration: duration);
});

final relatedProvider = FutureProvider.autoDispose.family<List<Section>, String>((ref, videoId) async {
  final ep = (await ref.watch(nextInfoProvider(videoId).future)).relatedEndpoint;
  return ep == null ? const [] : ref.watch(innerTubeProvider).related(ep);
});

/// Paged state shared by home, search results and playlists.
@immutable
class Paged<T> {
  const Paged(this.value, {this.continuation, this.loadingMore = false});

  final T value;
  final String? continuation;
  final bool loadingMore;

  bool get hasMore => continuation != null;
}

final homeProvider = AsyncNotifierProvider<HomeController, Paged<HomePage>>(HomeController.new);

class HomeController extends AsyncNotifier<Paged<HomePage>> {
  BrowseEndpoint? _chip;
  BrowseEndpoint? get selectedChip => _chip;

  @override
  Future<Paged<HomePage>> build() async {
    await ref.watch(authProvider.future);
    final yt = ref.watch(innerTubeProvider);
    await yt.ensureVisitorData();
    final page = await yt.home(chip: _chip);
    return Paged(page, continuation: page.continuation);
  }

  Future<void> selectChip(HomeChip chip) async {
    _chip = chip.endpoint == _chip ? null : chip.endpoint;
    state = const AsyncLoading();
    ref.invalidateSelf();
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(Paged(current.value, continuation: current.continuation, loadingMore: true));
    try {
      final more = await ref.read(innerTubeProvider).sectionsContinuation(current.continuation!);
      final page = current.value;
      state = AsyncData(
        Paged(
          HomePage(chips: page.chips, sections: [...page.sections, ...more.sections], continuation: more.continuation),
          continuation: more.continuation,
        ),
      );
    } catch (e) {
      state = AsyncData(Paged(current.value, continuation: current.continuation));
    }
  }
}

typedef SearchQuery = ({String query, SearchFilter? filter});

final searchResultsProvider = AsyncNotifierProvider.autoDispose
    .family<SearchController, Paged<SearchPage>, SearchQuery>(SearchController.new);

class SearchController extends AsyncNotifier<Paged<SearchPage>> {
  SearchController(this.arg);

  final SearchQuery arg;

  @override
  Future<Paged<SearchPage>> build() async {
    final page = await ref.watch(innerTubeProvider).search(arg.query, filter: arg.filter);
    return Paged(page, continuation: page.continuation);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(Paged(current.value, continuation: current.continuation, loadingMore: true));
    try {
      final more = await ref.read(innerTubeProvider).searchContinuation(current.continuation!);
      state = AsyncData(
        Paged(
          SearchPage(items: [...current.value.items, ...more.items], continuation: more.continuation),
          continuation: more.continuation,
        ),
      );
    } catch (e) {
      state = AsyncData(Paged(current.value, continuation: current.continuation));
    }
  }
}

final playlistProvider = AsyncNotifierProvider.autoDispose.family<PlaylistController, Paged<PlaylistPage>, String>(
  PlaylistController.new,
);

class PlaylistController extends AsyncNotifier<Paged<PlaylistPage>> {
  PlaylistController(this.playlistId);

  final String playlistId;
  final related = <Section>[];

  @override
  Future<Paged<PlaylistPage>> build() async {
    final page = await ref.watch(innerTubeProvider).playlist(playlistId);
    return Paged(page, continuation: page.continuation);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(Paged(current.value, continuation: current.continuation, loadingMore: true));
    try {
      final more = await ref.read(innerTubeProvider).playlistContinuation(current.continuation!);
      related.addAll(more.sections);
      final p = current.value;
      state = AsyncData(
        Paged(
          PlaylistPage(
            playlist: p.playlist,
            songs: [...p.songs, ...more.songs],
            description: p.description,
            secondSubtitle: p.secondSubtitle,
            continuation: more.continuation,
          ),
          continuation: more.continuation,
        ),
      );
    } catch (e) {
      state = AsyncData(Paged(current.value, continuation: current.continuation));
    }
  }

  /// All songs, following continuations (for play/shuffle of long playlists).
  Future<List<SongItem>> allSongs() async {
    while (state.value?.hasMore == true && state.value!.value.songs.length < 1000) {
      final before = state.value!.value.songs.length;
      await loadMore();
      if (state.value!.value.songs.length == before) break;
    }
    return state.value?.value.songs ?? const [];
  }
}

// Library streams ------------------------------------------------------------------------------

final isLikedProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, id) => ref.watch(libraryProvider).watchIsLiked(id),
);
final isSavedProvider = StreamProvider.autoDispose.family<bool, YTItem>(
  (ref, item) => ref.watch(libraryProvider).watchIsSaved(item),
);
final likedSongsProvider = StreamProvider<List<SongItem>>((ref) => ref.watch(libraryProvider).watchLikedSongs());
final historyProvider = StreamProvider<List<SongItem>>((ref) => ref.watch(libraryProvider).watchHistory());
final savedAlbumsProvider = StreamProvider<List<AlbumItem>>((ref) => ref.watch(libraryProvider).watchSavedAlbums());
final savedArtistsProvider = StreamProvider<List<ArtistItem>>((ref) => ref.watch(libraryProvider).watchSavedArtists());
final savedPlaylistsProvider = StreamProvider<List<PlaylistItem>>(
  (ref) => ref.watch(libraryProvider).watchSavedPlaylists(),
);
final localPlaylistsProvider = StreamProvider<List<LocalPlaylistSummary>>(
  (ref) => ref.watch(libraryProvider).watchLocalPlaylists(),
);
final searchHistoryProvider = StreamProvider<List<String>>((ref) => ref.watch(libraryProvider).watchSearchHistory());
