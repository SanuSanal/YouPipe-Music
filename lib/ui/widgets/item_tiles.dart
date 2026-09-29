import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../navigation.dart';
import '../theme/ytm_theme.dart';
import 'item_menu.dart';
import 'thumbnail.dart';

/// Subtitle for a row. Search rows lead with the type ("Song • ..."), like YouTube Music.
String rowSubtitle(YTItem item) => item.subtitle;

/// YouTube Music's list row (`musicResponsiveListItemRenderer`).
class ResponsiveListTile extends ConsumerWidget {
  const ResponsiveListTile({
    super.key,
    required this.item,
    this.onTap,
    this.index,
    this.subtitle,
    this.trailing,
    this.showMenu = true,
  });

  final YTItem item;
  final VoidCallback? onTap;

  /// Album tracks show their number instead of artwork.
  final int? index;
  final String? subtitle;
  final Widget? trailing;
  final bool showMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = item is SongItem && ref.watch(currentSongProvider)?.videoId == item.id;
    final downloaded = item is SongItem && ref.watch(downloadedIdsProvider).contains(item.id);
    final theme = Theme.of(context);

    final Widget leading;
    if (index != null) {
      leading = SizedBox(
        width: 32,
        child: isCurrent
            ? const Icon(Icons.graphic_eq, color: YtmColors.textPrimary, size: 20)
            : Text('$index', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
      );
    } else {
      leading = Stack(
        alignment: Alignment.center,
        children: [
          YtImage(
            thumbnails: item.thumbnails,
            size: YtmSizes.listThumb,
            circle: item is ArtistItem,
            fallbackIcon: item is ArtistItem ? Icons.person : Icons.music_note,
          ),
          if (isCurrent)
            Container(
              width: YtmSizes.listThumb,
              height: YtmSizes.listThumb,
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
              child: const Icon(Icons.graphic_eq, color: Colors.white),
            ),
        ],
      );
    }

    final explicit = switch (item) {
      SongItem(:final explicit) || AlbumItem(:final explicit) => explicit,
      _ => false,
    };

    return InkWell(
      onTap: onTap ?? () => openItem(context, ref, item),
      onLongPress: showMenu ? () => showItemMenu(context, ref, item) : null,
      child: Padding(
        padding: const EdgeInsets.only(left: YtmSizes.pagePadding, top: 8, bottom: 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                  if ((subtitle ?? rowSubtitle(item)).isNotEmpty || explicit || downloaded) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (downloaded)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.download_done, size: 16, color: YtmColors.textSecondary),
                          ),
                        if (explicit) const ExplicitBadge(),
                        Expanded(
                          child: Text(
                            subtitle ?? rowSubtitle(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
            if (showMenu)
              IconButton(
                icon: const Icon(Icons.more_vert),
                color: YtmColors.textPrimary,
                onPressed: () => showItemMenu(context, ref, item),
              )
            else
              const SizedBox(width: YtmSizes.pagePadding),
          ],
        ),
      ),
    );
  }
}

class ExplicitBadge extends StatelessWidget {
  const ExplicitBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(color: YtmColors.textSecondary, borderRadius: BorderRadius.circular(2)),
    child: const Text(
      'E',
      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

/// YouTube Music's carousel card (`musicTwoRowItemRenderer`).
class TwoRowCard extends ConsumerWidget {
  const TwoRowCard({super.key, required this.item, this.width = YtmSizes.carouselCard});

  final YTItem item;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isArtist = item is ArtistItem;
    final isVideo = item is SongItem && (item as SongItem).isVideo;
    return InkWell(
      onTap: () => openItem(context, ref, item),
      onLongPress: () => showItemMenu(context, ref, item),
      borderRadius: BorderRadius.circular(YtmSizes.cardRadius),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: isArtist ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            YtImage(
              thumbnails: item.thumbnails,
              size: width,
              aspectRatio: isVideo ? 16 / 9 : 1,
              circle: isArtist,
              fallbackIcon: isArtist ? Icons.person : Icons.album,
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: isArtist ? TextAlign.center : TextAlign.start,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: isArtist ? TextAlign.center : TextAlign.start,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mood/genre tile with the colored left stripe.
class MoodTile extends ConsumerWidget {
  const MoodTile({super.key, required this.mood, this.width});

  final MoodItem mood;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: width,
      height: 48,
      child: Material(
        color: YtmColors.surface,
        borderRadius: BorderRadius.circular(YtmSizes.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openBrowse(context, ref, mood.endpoint, title: mood.title),
          child: Row(
            children: [
              Container(width: 6, color: mood.color == null ? YtmColors.textSecondary : Color(mood.color!)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mood.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
