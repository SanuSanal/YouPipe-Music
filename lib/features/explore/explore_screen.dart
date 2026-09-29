import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/navigation.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/logo.dart';
import '../../ui/widgets/shelves.dart';
import '../../ui/widgets/states.dart';

IconData _shortcutIcon(String title) => switch (title) {
  'New releases' => Icons.new_releases_outlined,
  'Charts' => Icons.trending_up,
  _ => Icons.emoji_emotions_outlined,
};

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explore = ref.watch(exploreProvider);
    return Scaffold(
      body: RefreshIndicator(
        color: YtmColors.textPrimary,
        backgroundColor: YtmColors.surface,
        onRefresh: () => ref.refresh(exploreProvider.future),
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              floating: true,
              snap: true,
              titleSpacing: YtmSizes.pagePadding,
              title: YouPipeWordmark(),
              actions: [TopBarActions()],
            ),
            ...switch (explore) {
              AsyncData(:final value) => [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(YtmSizes.pagePadding, 8, YtmSizes.pagePadding, 0),
                  sliver: SliverList.separated(
                    itemCount: value.shortcuts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _ShortcutButton(item: value.shortcuts[i]),
                  ),
                ),
                SliverList.builder(
                  itemCount: value.sections.length,
                  itemBuilder: (context, i) => SectionView(section: value.sections[i]),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
              AsyncError(:final error) => [
                SliverFillRemaining(
                  child: ErrorView(error: error, onRetry: () => ref.invalidate(exploreProvider)),
                ),
              ],
              _ => [const SliverFillRemaining(child: LoadingView())],
            },
          ],
        ),
      ),
    );
  }
}

/// The big "New releases / Charts / Moods & genres" buttons at the top of Explore.
class _ShortcutButton extends ConsumerWidget {
  const _ShortcutButton({required this.item});

  final MoodItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: YtmColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => openBrowse(context, ref, item.endpoint, title: item.title),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(_shortcutIcon(item.title), color: YtmColors.textPrimary),
              const SizedBox(width: 16),
              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
