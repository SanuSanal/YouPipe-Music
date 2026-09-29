import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account.dart';

import 'package:share_plus/share_plus.dart';

import '../../data/db/app_database.dart' show DownloadStatus;
import '../../innertube/models.dart';
import '../../providers.dart';
import '../navigation.dart';
import '../theme/ytm_theme.dart';
import 'states.dart';
import 'thumbnail.dart';
import '../../features/player/player_options.dart';

String shareUrl(YTItem item) => switch (item) {
  SongItem() => 'https://music.youtube.com/watch?v=${item.videoId}',
  AlbumItem(:final playlistId?) => 'https://music.youtube.com/playlist?list=$playlistId',
  AlbumItem() => 'https://music.youtube.com/browse/${item.browseId}',
  ArtistItem() => 'https://music.youtube.com/channel/${item.browseId}',
  PlaylistItem() => 'https://music.youtube.com/playlist?list=${item.id}',
};

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
}

/// Songs behind an album/playlist item, for "Play next" / "Add to queue".
Future<List<SongItem>> _songsOf(WidgetRef ref, YTItem item) async {
  final yt = ref.read(innerTubeProvider);
  return switch (item) {
    SongItem() => [item],
    AlbumItem() => (await yt.album(item.browseId)).songs,
    PlaylistItem() => (await yt.playlist(item.id)).songs,
    ArtistItem() => const [],
  };
}

/// The long-press / ⋮ bottom sheet from YouTube Music.
/// [inPlayer] adds the player-only entries (sleep timer, speed, equalizer).
Future<void> showItemMenu(BuildContext context, WidgetRef ref, YTItem item, {bool inPlayer = false}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ItemMenu(item: item, hostContext: context, inPlayer: inPlayer),
  );
}

class _ItemMenu extends ConsumerWidget {
  const _ItemMenu({required this.item, required this.hostContext, this.inPlayer = false});

  final YTItem item;
  final bool inPlayer;

  /// Context of the screen that opened the menu (the sheet's own context dies on close).
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isSavedProvider(item)).value ?? false;
    final actions = ref.read(playerActionsProvider);
    final account = ref.read(accountActionsProvider);
    final downloads = ref.read(downloadManagerProvider);
    final downloadStatus = item is SongItem ? ref.watch(downloadStatusProvider(item.id)) : null;

    void run(Future<void> Function() action, [String? toast]) {
      Navigator.of(context).pop();
      action().then(
        (_) {
          if (toast != null && hostContext.mounted) showSnack(hostContext, toast);
        },
        onError: (Object e) {
          if (hostContext.mounted) showSnack(hostContext, 'Something went wrong');
        },
      );
    }

    final tiles = <Widget>[
      if (inPlayer) ...[
        ListTile(
          leading: const Icon(Icons.bedtime_outlined, color: YtmColors.textPrimary),
          title: const Text('Sleep timer'),
          subtitle: Text(sleepTimerLabel(ref)),
          onTap: () {
            Navigator.of(context).pop();
            showSleepTimerSheet(hostContext, ref);
          },
        ),
        _tile(Icons.speed, 'Playback speed', () {
          Navigator.of(context).pop();
          showSpeedSheet(hostContext, ref);
        }),
        _tile(Icons.equalizer, 'Equalizer', () {
          Navigator.of(context).pop();
          showEqualizerSheet(hostContext);
        }),
        const Divider(),
      ],
      if (item case SongItem song) ...[
        _tile(Icons.sensors, 'Start radio', () => run(() => actions.startRadio(song))),
        _tile(Icons.playlist_play, 'Play next', () => run(() async => actions.playNext([song]), 'Song will play next')),
        _tile(
          Icons.queue_music,
          'Add to queue',
          () => run(() async => actions.addToQueue([song]), 'Song added to queue'),
        ),
        _tile(
          saved ? Icons.thumb_up : Icons.thumb_up_outlined,
          saved ? 'Remove from liked songs' : 'Add to liked songs',
          () => run(() => account.setLiked(song, !saved), saved ? 'Removed from liked songs' : 'Added to liked songs'),
        ),
        _tile(Icons.playlist_add, 'Save to playlist', () {
          Navigator.of(context).pop();
          showSaveToPlaylist(hostContext, ref, [song]);
        }),
        if (downloadStatus == null || downloadStatus == DownloadStatus.failed)
          _tile(Icons.download_outlined, 'Download', () => run(() => downloads.enqueue([song]), 'Downloading…'))
        else
          _tile(
            downloadStatus == DownloadStatus.done ? Icons.download_done : Icons.downloading,
            downloadStatus == DownloadStatus.done ? 'Remove download' : 'Cancel download',
            () => run(() => downloads.remove(song.videoId), 'Download removed'),
          ),
        if (song.album != null)
          _tile(Icons.album_outlined, 'Go to album', () {
            Navigator.of(context).pop();
            openAlbum(hostContext, ref, song.album!.id);
          }),
        for (final artist in song.artists.where((a) => a.id != null).take(1))
          _tile(Icons.person_outline, 'Go to artist', () {
            Navigator.of(context).pop();
            openArtist(hostContext, ref, artist.id!);
          }),
      ],
      if (item is AlbumItem || item is PlaylistItem) ...[
        if (item case PlaylistItem(isRadio: true)) ...[
          _tile(Icons.play_arrow, 'Play', () => run(() => actions.playEndpoint(WatchEndpoint(playlistId: item.id)))),
        ] else ...[
          _tile(
            Icons.shuffle,
            'Shuffle play',
            () => run(() async {
              final songs = await _songsOf(ref, item);
              await actions.playList(songs, shuffle: true, title: item.title);
            }),
          ),
          _tile(
            Icons.playlist_play,
            'Play next',
            () => run(
              () async => actions.playNext(await _songsOf(ref, item)),
              '${item is AlbumItem ? 'Album' : 'Playlist'} will play next',
            ),
          ),
          _tile(
            Icons.queue_music,
            'Add to queue',
            () => run(
              () async => actions.addToQueue(await _songsOf(ref, item)),
              '${item is AlbumItem ? 'Album' : 'Playlist'} added to queue',
            ),
          ),
          _tile(
            saved ? Icons.library_add_check : Icons.library_add_outlined,
            saved ? 'Remove from library' : 'Save to library',
            () => run(() => account.setSaved(item, !saved), saved ? 'Removed from library' : 'Saved to library'),
          ),
          _tile(Icons.playlist_add, 'Save to playlist', () {
            Navigator.of(context).pop();
            _songsOf(ref, item).then((songs) {
              if (hostContext.mounted) showSaveToPlaylist(hostContext, ref, songs);
            });
          }),
          _tile(
            Icons.download_outlined,
            'Download',
            () => run(() async => downloads.enqueue(await _songsOf(ref, item)), 'Downloading…'),
          ),
        ],
        if (item case AlbumItem(:final artists))
          for (final artist in artists.where((a) => a.id != null).take(1))
            _tile(Icons.person_outline, 'Go to artist', () {
              Navigator.of(context).pop();
              openArtist(hostContext, ref, artist.id!);
            }),
      ],
      if (item is ArtistItem)
        _tile(
          saved ? Icons.how_to_reg : Icons.person_add_alt,
          saved ? 'Unsubscribe' : 'Subscribe',
          () => run(() => account.setSaved(item, !saved), saved ? 'Unsubscribed' : 'Subscribed'),
        ),
      _tile(Icons.share_outlined, 'Share', () {
        Navigator.of(context).pop();
        SharePlus.instance.share(ShareParams(text: shareUrl(item)));
      }),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                YtImage(thumbnails: item.thumbnails, size: 48, circle: item is ArtistItem),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(child: ListView(shrinkWrap: true, children: tiles)),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: YtmColors.textPrimary),
    title: Text(label),
    onTap: onTap,
  );
}

/// Picks a local playlist (or creates one) and adds [songs] to it.
Future<void> showSaveToPlaylist(BuildContext context, WidgetRef ref, List<SongItem> songs) async {
  if (songs.isEmpty) return;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (sheet) => Consumer(
      builder: (sheet, ref, _) {
        final playlists = ref.watch(localPlaylistsProvider).value ?? const [];
        final library = ref.read(libraryProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Save to playlist', style: Theme.of(sheet).textTheme.titleLarge),
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('New playlist'),
                onTap: () async {
                  final name = await promptText(sheet, title: 'New playlist', hint: 'Title');
                  if (name == null || name.trim().isEmpty) return;
                  final id = await library.createPlaylist(name.trim());
                  await library.addToPlaylist(id, songs);
                  if (sheet.mounted) Navigator.of(sheet).pop();
                  if (context.mounted) showSnack(context, 'Saved to ${name.trim()}');
                },
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p
                        in ref.watch(accountLibraryProvider(LibraryPage.playlists)).value?.whereType<PlaylistItem>() ??
                            const <PlaylistItem>[])
                      // LM = Liked Music, SE = Episodes for later: not editable.
                      if (p.id != 'LM' && p.id != 'SE' && !p.isRadio)
                        ListTile(
                          leading: YtImage(thumbnails: p.thumbnails, size: 48, fallbackIcon: Icons.queue_music),
                          title: Text(p.title),
                          subtitle: const Text('YouTube Music'),
                          onTap: () async {
                            try {
                              await ref.read(innerTubeProvider).addToPlaylist(p.id, [for (final s in songs) s.videoId]);
                              if (context.mounted) showSnack(context, 'Saved to ${p.title}');
                            } catch (_) {
                              if (context.mounted) showSnack(context, "Couldn't add to ${p.title}");
                            }
                            if (sheet.mounted) Navigator.of(sheet).pop();
                          },
                        ),
                    for (final p in playlists)
                      ListTile(
                        leading: YtImage.url(p.thumbnailUrl, size: 48, fallbackIcon: Icons.queue_music),
                        title: Text(p.name),
                        subtitle: Text(songCount(p.songCount)),
                        onTap: () async {
                          await library.addToPlaylist(p.id, songs);
                          if (sheet.mounted) Navigator.of(sheet).pop();
                          if (context.mounted) showSnack(context, 'Saved to ${p.name}');
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<String?> promptText(BuildContext context, {required String title, String? hint, String? initial}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      backgroundColor: YtmColors.surface,
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
          border: const UnderlineInputBorder(),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: YtmColors.textPrimary)),
        ),
        onSubmitted: (v) => Navigator.of(dialog).pop(v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(dialog).pop(controller.text), child: const Text('Save')),
      ],
    ),
  );
}
