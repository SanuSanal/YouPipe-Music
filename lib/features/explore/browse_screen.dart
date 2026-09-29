import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/item_tiles.dart';
import '../../ui/widgets/shelves.dart';
import '../../ui/widgets/states.dart';

/// Any sections page: charts, new releases, moods & genres, mood categories, "More" pages.
class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key, required this.endpoint, this.title});

  final BrowseEndpoint endpoint;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(browseSectionsProvider(endpoint));
    return Scaffold(
      appBar: AppBar(title: Text(page.value?.title ?? title ?? '')),
      body: switch (page) {
        AsyncData(:final value) when value.sections.isEmpty => const EmptyView(
          icon: Icons.library_music_outlined,
          title: 'Nothing here yet',
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            for (final section in value.sections)
              if (section.moods.isNotEmpty)
                _MoodsGridSection(section: section)
              else if (value.sections.length == 1 && section.items.length > 12)
                _ItemGrid(items: section.items)
              else
                SectionView(section: section),
          ],
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(browseSectionsProvider(endpoint)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

/// "Moods & genres" page: titled 2-column grids of colored tiles.
class _MoodsGridSection extends StatelessWidget {
  const _MoodsGridSection({required this.section});

  final Section section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title.isNotEmpty) SectionHeader(title: section.title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: YtmSizes.pagePadding),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.4,
            children: [for (final m in section.moods) MoodTile(mood: m)],
          ),
        ),
      ],
    );
  }
}

/// Full-page grid of cards (e.g. an artist's albums, new releases).
class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items});

  final List<YTItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(YtmSizes.pagePadding),
      child: LayoutBuilder(
        builder: (context, c) {
          final columns = (c.maxWidth / 180).floor().clamp(2, 6);
          final width = (c.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 16,
            children: [for (final item in items) TwoRowCard(item: item, width: width)],
          );
        },
      ),
    );
  }
}
