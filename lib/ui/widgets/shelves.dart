import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../innertube/models.dart';
import '../navigation.dart';
import '../theme/ytm_theme.dart';
import 'item_tiles.dart';
import 'thumbnail.dart';

/// Shelf title row: optional avatar and strapline, the title, and a "More" pill.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.strapline,
    this.thumbnails = const [],
    this.onMore,
    this.moreLabel = 'More',
  });

  final String title;
  final String? strapline;
  final List<Thumbnail> thumbnails;
  final VoidCallback? onMore;
  final String moreLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(YtmSizes.pagePadding, 24, YtmSizes.pagePadding, 12),
      child: Row(
        children: [
          if (thumbnails.isNotEmpty) ...[
            YtImage(thumbnails: thumbnails, size: 40, circle: true),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (strapline != null && strapline!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      strapline!.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 0.5),
                    ),
                  ),
                Text(title, style: theme.textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (onMore != null) MorePill(label: moreLabel, onPressed: onMore!),
        ],
      ),
    );
  }
}

class MorePill extends StatelessWidget {
  const MorePill({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: YtmColors.textPrimary,
      side: const BorderSide(color: Color(0x33FFFFFF)),
      shape: const StadiumBorder(),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 14),
    ),
    child: Text(label),
  );
}

/// Renders any [Section] the way YouTube Music does: card carousel, Quick-picks grid, list or mood grid.
class SectionView extends ConsumerWidget {
  const SectionView({super.key, required this.section, this.listLimit});

  final Section section;

  /// For list shelves (artist "Top songs"), how many rows to show.
  final int? listLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final header = section.title.isEmpty
        ? const SizedBox(height: 8)
        : SectionHeader(
            title: section.title,
            strapline: section.strapline,
            thumbnails: section.thumbnails,
            onMore: section.moreEndpoint == null
                ? null
                : () => section.moreEndpoint!.browseId.startsWith('VL')
                      ? openPlaylist(context, ref, section.moreEndpoint!.browseId.substring(2))
                      : openBrowse(context, ref, section.moreEndpoint!, title: section.title),
          );

    final Widget body;
    if (section.moods.isNotEmpty) {
      body = MoodGrid(moods: section.moods, rows: section.itemsPerColumn ?? 4);
    } else if (section.itemsPerColumn != null || _isListShelf(section)) {
      body = section.itemsPerColumn != null
          ? QuickPicksGrid(items: section.items, rows: section.itemsPerColumn!)
          : Column(
              children: [
                for (final item in section.items.take(listLimit ?? section.items.length))
                  ResponsiveListTile(item: item),
              ],
            );
    } else {
      body = CardCarousel(items: section.items);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [header, body]);
  }

  /// Artist "Top songs" style shelves are vertical lists; carousels always have cards.
  static bool _isListShelf(Section s) =>
      s.items.isNotEmpty &&
      s.items.every((i) => i is SongItem && !i.isVideo) &&
      s.moreEndpoint?.browseId.startsWith('VL') == true;
}

class CardCarousel extends StatelessWidget {
  const CardCarousel({super.key, required this.items});

  final List<YTItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: YtmSizes.carouselCard + 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: YtmSizes.pagePadding),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          final video = item is SongItem && item.isVideo;
          // Video cards are 16:9 and as tall as the square ones.
          return TwoRowCard(item: item, width: video ? YtmSizes.carouselCard * 16 / 9 : YtmSizes.carouselCard);
        },
      ),
    );
  }
}

/// "Quick picks": horizontally paged columns of [rows] song rows.
class QuickPicksGrid extends StatelessWidget {
  const QuickPicksGrid({super.key, required this.items, this.rows = 4});

  final List<YTItem> items;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final columns = (items.length / rows).ceil();
    final width = MediaQuery.sizeOf(context).width * 0.88;
    return SizedBox(
      height: rows * 64.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(),
        itemCount: columns,
        itemBuilder: (context, c) => SizedBox(
          width: width,
          child: Column(
            children: [
              for (final item in items.skip(c * rows).take(rows))
                SizedBox(height: 64, child: ResponsiveListTile(item: item)),
            ],
          ),
        ),
      ),
    );
  }
}

class MoodGrid extends StatelessWidget {
  const MoodGrid({super.key, required this.moods, this.rows = 4});

  final List<MoodItem> moods;
  final int rows;

  @override
  Widget build(BuildContext context) {
    const tileWidth = 170.0;
    final columns = (moods.length / rows).ceil();
    return SizedBox(
      height: rows * 56.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: YtmSizes.pagePadding),
        itemCount: columns,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, c) => Column(
          children: [
            for (final m in moods.skip(c * rows).take(rows))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MoodTile(mood: m, width: tileWidth),
              ),
          ],
        ),
      ),
    );
  }
}
