import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/library_repository.dart';
import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/navigation.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/item_menu.dart';
import '../../ui/widgets/item_tiles.dart';
import '../../ui/widgets/logo.dart';
import '../../ui/widgets/states.dart';
import '../../ui/widgets/thumbnail.dart';
import '../home/home_screen.dart' show YtChip;

enum LibraryFilter { playlists, songs, albums, artists }

extension on LibraryFilter {
  String get label => switch (this) {
    LibraryFilter.playlists => 'Playlists',
    LibraryFilter.songs => 'Songs',
    LibraryFilter.albums => 'Albums',
    LibraryFilter.artists => 'Artists',
  };
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  LibraryFilter? _filter;
  bool _grid = false;

  @override
  Widget build(BuildContext context) {
    final liked = ref.watch(likedSongsProvider).value ?? const [];
    final local = ref.watch(localPlaylistsProvider).value ?? const <LocalPlaylistSummary>[];
    final playlists = ref.watch(savedPlaylistsProvider).value ?? const <PlaylistItem>[];
    final albums = ref.watch(savedAlbumsProvider).value ?? const <AlbumItem>[];
    final artists = ref.watch(savedArtistsProvider).value ?? const <ArtistItem>[];

    final entries = <_Entry>[
      if (_filter == null || _filter == LibraryFilter.playlists) ...[
        _Entry.special(
          title: 'Liked music',
          subtitle: 'Auto playlist • ${songCount(liked.length)}',
          icon: Icons.thumb_up,
          onTap: () => openLibraryList(context, ref, 'liked'),
        ),
        if (_filter == null)
          _Entry.special(
            title: 'History',
            subtitle: 'Recently played',
            icon: Icons.history,
            onTap: () => openLibraryList(context, ref, 'history'),
          ),
        for (final p in local) _Entry.local(p, onTap: () => openLocalPlaylist(context, ref, p.id)),
        for (final p in playlists) _Entry.item(p),
      ],
      if (_filter == null || _filter == LibraryFilter.albums)
        for (final a in albums) _Entry.item(a),
      if (_filter == null || _filter == LibraryFilter.artists)
        for (final a in artists) _Entry.item(a),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            snap: true,
            titleSpacing: YtmSizes.pagePadding,
            title: YouPipeWordmark(),
            actions: [TopBarActions()],
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(YtmSizes.pagePadding, 6, YtmSizes.pagePadding, 10),
                children: [
                  if (_filter != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: YtChip(label: '✕', selected: false, onTap: () => setState(() => _filter = null)),
                    ),
                  for (final f in LibraryFilter.values)
                    if (_filter == null || _filter == f)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: YtChip(
                          label: f.label,
                          selected: _filter == f,
                          onTap: () => setState(() => _filter = _filter == f ? null : f),
                        ),
                      ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: YtmSizes.pagePadding - 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.sort, color: YtmColors.textPrimary, size: 20),
                    label: const Text('Recent activity', style: TextStyle(color: YtmColors.textPrimary)),
                  ),
                  const Spacer(),
                  if (_filter == null || _filter == LibraryFilter.playlists)
                    IconButton(
                      tooltip: 'New playlist',
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final name = await promptText(context, title: 'New playlist', hint: 'Title');
                        if (name != null && name.trim().isNotEmpty) {
                          await ref.read(libraryProvider).createPlaylist(name.trim());
                        }
                      },
                    ),
                  IconButton(
                    tooltip: _grid ? 'List view' : 'Grid view',
                    icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
                    onPressed: () => setState(() => _grid = !_grid),
                  ),
                ],
              ),
            ),
          ),
          if (_filter == LibraryFilter.songs)
            liked.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(
                      icon: Icons.thumb_up_outlined,
                      title: 'No liked songs yet',
                      message: 'Songs you like will show up here.',
                    ),
                  )
                : SliverList.builder(
                    itemCount: liked.length,
                    itemBuilder: (context, i) => ResponsiveListTile(
                      item: liked[i],
                      onTap: () => ref.read(playerActionsProvider).playList(liked, index: i, title: 'Liked music'),
                    ),
                  )
          else if (entries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(icon: Icons.library_music_outlined, title: 'Nothing saved yet'),
            )
          else if (_grid)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: YtmSizes.pagePadding),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: entries.length,
                itemBuilder: (context, i) => entries[i].buildCard(context, ref),
              ),
            )
          else
            SliverList.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) => entries[i].buildRow(context, ref),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }
}

/// A library row: a real item, a local playlist or a special entry (Liked music, History).
class _Entry {
  _Entry.item(YTItem this.item)
    : title = item.title,
      subtitle = item.subtitle,
      icon = null,
      imageUrl = null,
      onTap = null;

  _Entry.local(LocalPlaylistSummary p, {required this.onTap})
    : item = null,
      title = p.name,
      subtitle = 'Playlist • ${songCount(p.songCount)}',
      icon = Icons.queue_music,
      imageUrl = p.thumbnailUrl;

  _Entry.special({required this.title, required this.subtitle, required IconData this.icon, required this.onTap})
    : item = null,
      imageUrl = null;

  final YTItem? item;
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? imageUrl;
  final VoidCallback? onTap;

  Widget _art(double size) {
    if (item != null) return YtImage(thumbnails: item!.thumbnails, size: size, circle: item is ArtistItem);
    if (imageUrl != null) return YtImage.url(imageUrl, size: size);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(colors: [Color(0xFF5E35B1), Color(0xFFD81B60)]),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.45),
    );
  }

  Widget buildRow(BuildContext context, WidgetRef ref) {
    if (item != null) return ResponsiveListTile(item: item!);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: YtmSizes.pagePadding, vertical: 2),
      leading: _art(YtmSizes.listThumb),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      onTap: onTap,
    );
  }

  Widget buildCard(BuildContext context, WidgetRef ref) {
    if (item != null) {
      return LayoutBuilder(
        builder: (context, c) => TwoRowCard(item: item!, width: c.maxWidth),
      );
    }
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, c) => _art(c.maxWidth)),
          const SizedBox(height: 8),
          Text(title, maxLines: 2, style: Theme.of(context).textTheme.titleSmall),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
