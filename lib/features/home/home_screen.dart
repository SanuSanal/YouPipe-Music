import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/logo.dart';
import '../../ui/widgets/shelves.dart';
import '../../ui/widgets/states.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final controller = ref.read(homeProvider.notifier);
    final chips = home.value?.value.chips.where((c) => c.title != 'Podcasts').toList() ?? const <HomeChip>[];

    return Scaffold(
      body: RefreshIndicator(
        color: YtmColors.textPrimary,
        backgroundColor: YtmColors.surface,
        onRefresh: () => ref.refresh(homeProvider.future),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 600) controller.loadMore();
            return false;
          },
          child: CustomScrollView(
            slivers: [
              const SliverAppBar(
                floating: true,
                snap: true,
                titleSpacing: YtmSizes.pagePadding,
                title: YouPipeWordmark(),
                actions: [TopBarActions()],
              ),
              if (chips.isNotEmpty)
                SliverToBoxAdapter(
                  child: ChipsRow(chips: chips, selected: controller.selectedChip, onTap: controller.selectChip),
                ),
              ...switch (home) {
                AsyncData(:final value) => [
                  SliverList.builder(
                    itemCount: value.value.sections.length,
                    itemBuilder: (context, i) => SectionView(section: value.value.sections[i]),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: 120, child: value.loadingMore ? const LoadingView() : null),
                  ),
                ],
                AsyncError(:final error) => [
                  SliverFillRemaining(
                    child: ErrorView(error: error, onRetry: () => ref.invalidate(homeProvider)),
                  ),
                ],
                _ => [const SliverFillRemaining(child: LoadingView())],
              },
            ],
          ),
        ),
      ),
    );
  }
}

/// Mood filter chips under the app bar (Energize, Workout, Relax...).
class ChipsRow extends StatelessWidget {
  const ChipsRow({super.key, required this.chips, required this.onTap, this.selected});

  final List<HomeChip> chips;
  final BrowseEndpoint? selected;
  final ValueChanged<HomeChip> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(YtmSizes.pagePadding, 6, YtmSizes.pagePadding, 10),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = chips[i];
          final isSelected = chip.selected || chip.endpoint == selected;
          return YtChip(label: chip.title, selected: isSelected, onTap: () => onTap(chip));
        },
      ),
    );
  }
}

class YtChip extends StatelessWidget {
  const YtChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? YtmColors.chipSelected : YtmColors.chip,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : YtmColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
