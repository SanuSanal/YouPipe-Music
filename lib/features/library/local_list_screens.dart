import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/item_menu.dart';
import '../../ui/widgets/item_tiles.dart';
import '../../ui/widgets/states.dart';

/// "Liked music" and "History".
class LibraryListScreen extends ConsumerWidget {
  const LibraryListScreen({super.key, required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = kind == 'liked';
    final songs = ref.watch(liked ? likedSongsProvider : historyProvider);
    final title = liked ? 'Liked music' : 'History';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!liked)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref.read(libraryProvider).clearHistory(),
            ),
        ],
      ),
      body: switch (songs) {
        AsyncData(:final value) when value.isEmpty => EmptyView(
          icon: liked ? Icons.thumb_up_outlined : Icons.history,
          title: liked ? 'No liked songs yet' : 'Nothing played yet',
        ),
        AsyncData(:final value) => _SongList(songs: value, title: title),
        AsyncError(:final error) => ErrorView(error: error),
        _ => const LoadingView(),
      },
    );
  }
}

class _SongList extends ConsumerWidget {
  const _SongList({required this.songs, required this.title});

  final List<SongItem> songs;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(playerActionsProvider);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 140),
      itemCount: songs.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return PlayShuffleBar(
            onPlay: () => actions.playList(songs, title: title),
            onShuffle: () => actions.playList(songs, shuffle: true, title: title),
          );
        }
        return ResponsiveListTile(
          item: songs[i - 1],
          onTap: () => actions.playList(songs, index: i - 1, title: title),
        );
      },
    );
  }
}

class PlayShuffleBar extends StatelessWidget {
  const PlayShuffleBar({super.key, required this.onPlay, required this.onShuffle});

  final VoidCallback onPlay;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(YtmSizes.pagePadding, 8, YtmSizes.pagePadding, 8),
    child: Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onPlay,
            style: FilledButton.styleFrom(
              backgroundColor: YtmColors.textPrimary,
              foregroundColor: Colors.black,
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShuffle,
            style: OutlinedButton.styleFrom(
              foregroundColor: YtmColors.textPrimary,
              side: const BorderSide(color: Color(0x33FFFFFF)),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.shuffle),
            label: const Text('Shuffle'),
          ),
        ),
      ],
    ),
  );
}

final _localPlaylistSongsProvider = StreamProvider.autoDispose.family<List<(int, SongItem)>, int>(
  (ref, id) => ref.watch(libraryProvider).watchLocalPlaylistSongs(id),
);
final _localPlaylistNameProvider = StreamProvider.autoDispose.family<String?, int>(
  (ref, id) => ref.watch(libraryProvider).watchLocalPlaylistName(id),
);

/// A playlist created in YouPipe: play, shuffle, reorder, remove, rename, delete.
class LocalPlaylistScreen extends ConsumerWidget {
  const LocalPlaylistScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(_localPlaylistNameProvider(id)).value ?? '';
    final rows = ref.watch(_localPlaylistSongsProvider(id)).value ?? const [];
    final songs = rows.map((r) => r.$2).toList();
    final library = ref.read(libraryProvider);
    final actions = ref.read(playerActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          PopupMenuButton<String>(
            color: YtmColors.surface,
            onSelected: (v) async {
              if (v == 'rename') {
                final newName = await promptText(context, title: 'Rename playlist', initial: name);
                if (newName != null && newName.trim().isNotEmpty) await library.renamePlaylist(id, newName.trim());
              } else if (v == 'delete') {
                await library.deletePlaylist(id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete playlist')),
            ],
          ),
        ],
      ),
      body: songs.isEmpty
          ? const EmptyView(
              icon: Icons.queue_music,
              title: 'This playlist is empty',
              message: 'Use "Save to playlist" on any song to add it here.',
            )
          : Column(
              children: [
                PlayShuffleBar(
                  onPlay: () => actions.playList(songs, title: name),
                  onShuffle: () => actions.playList(songs, shuffle: true, title: name),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 140),
                    itemCount: rows.length,
                    onReorderItem: (from, to) => library.reorderPlaylist(id, from, to),
                    itemBuilder: (context, i) => Dismissible(
                      key: ValueKey(rows[i].$1),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: YtmColors.brandRed,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(Icons.delete_outline),
                      ),
                      onDismissed: (_) => library.removeFromPlaylist(rows[i].$1),
                      child: ResponsiveListTile(
                        item: rows[i].$2,
                        onTap: () => actions.playList(songs, index: i, title: name),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
