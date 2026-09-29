import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account.dart';

import 'package:share_plus/share_plus.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/navigation.dart';
import '../../ui/widgets/collection_header.dart';
import '../../ui/widgets/item_menu.dart';
import '../../ui/widgets/item_tiles.dart';
import '../../ui/widgets/shelves.dart';
import '../../ui/widgets/states.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(playlistProvider(playlistId));
    return switch (page) {
      AsyncData(:final value) => _PlaylistView(playlistId: playlistId, paged: value),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: error, onRetry: () => ref.invalidate(playlistProvider(playlistId))),
      ),
      _ => Scaffold(appBar: AppBar(), body: const LoadingView()),
    };
  }
}

class _PlaylistView extends ConsumerWidget {
  const _PlaylistView({required this.playlistId, required this.paged});

  final String playlistId;
  final Paged<PlaylistPage> paged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = paged.value;
    final playlist = page.playlist;
    final saved = ref.watch(isSavedProvider(playlist)).value ?? false;
    final actions = ref.read(playerActionsProvider);
    final downloadedIds = ref.watch(downloadedIdsProvider);
    final controller = ref.read(playlistProvider(playlistId).notifier);
    final author = playlist.author;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 800) controller.loadMore();
        return false;
      },
      child: TintedPage(
        title: playlist.title,
        artworkUrl: playlist.thumbnails.best(120),
        slivers: [
          SliverToBoxAdapter(
            child: CollectionHeader(
              thumbnails: playlist.thumbnails,
              title: playlist.title,
              ownerName: author?.name,
              onOwnerTap: author?.id == null ? null : () => openArtist(context, ref, author!.id!),
              meta: playlist.subtitle,
              secondMeta: page.secondSubtitle,
              description: page.description,
              saved: saved,
              onPlay: () async => actions.playList(await controller.allSongs(), title: playlist.title),
              downloaded: page.songs.isNotEmpty && page.songs.every((s) => downloadedIds.contains(s.videoId)),
              onDownload: () {
                ref.read(downloadManagerProvider).enqueue(page.songs);
                showSnack(context, 'Downloading ${songCount(page.songs.length)}');
              },
              onShuffle: () async =>
                  actions.playList(await controller.allSongs(), shuffle: true, title: playlist.title),
              onSave: () {
                ref.read(accountActionsProvider).setSaved(playlist, !saved);
                showSnack(context, saved ? 'Removed from library' : 'Saved to library');
              },
              onShare: () => SharePlus.instance.share(ShareParams(text: shareUrl(playlist))),
              onMore: () => showItemMenu(context, ref, playlist),
            ),
          ),
          SliverList.builder(
            itemCount: page.songs.length,
            itemBuilder: (context, i) => ResponsiveListTile(
              item: page.songs[i],
              subtitle: [
                page.songs[i].artistNames,
                if (page.songs[i].duration != null) _fmt(page.songs[i].duration!),
              ].where((s) => s.isNotEmpty).join(' • '),
              onTap: () => actions.playList(page.songs, index: i, title: playlist.title),
            ),
          ),
          if (paged.loadingMore)
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(16), child: LoadingView()),
            ),
          for (final section in controller.related) SliverToBoxAdapter(child: SectionView(section: section)),
        ],
      ),
    );
  }
}

String _fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
