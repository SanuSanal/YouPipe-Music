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

class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key, required this.browseId});

  final String browseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(albumProvider(browseId));
    return switch (page) {
      AsyncData(:final value) => _AlbumView(page: value),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: error, onRetry: () => ref.invalidate(albumProvider(browseId))),
      ),
      _ => Scaffold(appBar: AppBar(), body: const LoadingView()),
    };
  }
}

class _AlbumView extends ConsumerWidget {
  const _AlbumView({required this.page});

  final AlbumPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final album = page.album;
    final saved = ref.watch(isSavedProvider(album)).value ?? false;
    final actions = ref.read(playerActionsProvider);
    final allDownloaded = ref.watch(
      downloadedIdsProvider.select((ids) => page.songs.isNotEmpty && page.songs.every((s) => ids.contains(s.videoId))),
    );
    final artist = album.artists.where((a) => a.id != null).firstOrNull;

    return TintedPage(
      title: album.title,
      artworkUrl: album.thumbnails.best(120),
      slivers: [
        SliverToBoxAdapter(
          child: CollectionHeader(
            thumbnails: album.thumbnails,
            title: album.title,
            ownerName: album.artists.map((a) => a.name).join(', '),
            onOwnerTap: artist == null ? null : () => openArtist(context, ref, artist.id!),
            meta: [?album.typeLabel, ?album.year].join(' • '),
            secondMeta: page.secondSubtitle,
            description: page.description,
            saved: saved,
            onPlay: () => actions.playList(page.songs, title: album.title),
            downloaded: allDownloaded,
            onDownload: () {
              ref.read(downloadManagerProvider).enqueue(page.songs);
              showSnack(context, 'Downloading ${songCount(page.songs.length)}');
            },
            onShuffle: () => actions.playList(page.songs, shuffle: true, title: album.title),
            onSave: () {
              ref.read(accountActionsProvider).setSaved(album, !saved);
              showSnack(context, saved ? 'Removed from library' : 'Saved to library');
            },
            onShare: () => SharePlus.instance.share(ShareParams(text: shareUrl(album))),
            onMore: () => showItemMenu(context, ref, album),
          ),
        ),
        SliverList.builder(
          itemCount: page.songs.length,
          itemBuilder: (context, i) {
            final song = page.songs[i];
            return ResponsiveListTile(
              item: song,
              index: i + 1,
              // Album rows only show the artist when it differs from the album's.
              subtitle: song.artistNames == album.artists.map((a) => a.name).join(', ') ? '' : song.artistNames,
              onTap: () => actions.playList(page.songs, index: i, title: album.title),
            );
          },
        ),
        for (final section in page.otherSections) SliverToBoxAdapter(child: SectionView(section: section)),
      ],
    );
  }
}
