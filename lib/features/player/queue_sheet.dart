import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/audio_handler.dart';
import '../../providers.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/item_menu.dart';
import '../../ui/widgets/shelves.dart';
import '../../ui/widgets/states.dart';
import '../../ui/widgets/thumbnail.dart';

const _tabs = ['UP NEXT', 'LYRICS', 'RELATED'];

/// The UP NEXT | LYRICS | RELATED strip at the bottom of the full player.
class QueueTabsBar extends StatelessWidget {
  const QueueTabsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, label) in _tabs.indexed)
          Expanded(
            child: InkWell(
              onTap: () => showQueueSheet(context, initialTab: i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.6, fontSize: 13),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> showQueueSheet(BuildContext context, {int initialTab = 0}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: DefaultTabController(
        length: _tabs.length,
        initialIndex: initialTab,
        child: Column(
          children: [
            TabBar(
              tabs: [for (final t in _tabs) Tab(text: t)],
              indicatorColor: YtmColors.textPrimary,
              labelColor: YtmColors.textPrimary,
              unselectedLabelColor: YtmColors.textSecondary,
              dividerColor: YtmColors.divider,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.6),
            ),
            const Expanded(child: TabBarView(children: [_UpNextTab(), _LyricsTab(), _RelatedTab()])),
          ],
        ),
      ),
    ),
  );
}

class _UpNextTab extends ConsumerWidget {
  const _UpNextTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(queueStateProvider).value ?? const QueueState();
    final handler = ref.read(audioHandlerProvider);
    final theme = Theme.of(context);
    if (q.songs.isEmpty) return const EmptyView(icon: Icons.queue_music, title: 'Queue is empty');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Playing from', style: theme.textTheme.bodySmall),
                    Text(q.title ?? 'Queue', style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Shuffle',
                icon: Icon(Icons.shuffle, color: q.shuffle ? YtmColors.textPrimary : YtmColors.textSecondary),
                onPressed: handler.toggleShuffle,
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: q.songs.length,
            onReorderItem: (from, to) => handler.moveInQueue(from, to),
            itemBuilder: (context, i) {
              final song = q.songs[i];
              final current = i == q.index;
              return Dismissible(
                key: ValueKey('${song.videoId}-$i'),
                direction: current ? DismissDirection.none : DismissDirection.endToStart,
                onDismissed: (_) => handler.removeFromQueue(i),
                background: Container(
                  color: YtmColors.brandRed,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(Icons.delete_outline),
                ),
                child: Material(
                  color: current ? const Color(0x1AFFFFFF) : Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 16, right: 4),
                    leading: Stack(
                      alignment: Alignment.center,
                      children: [
                        YtImage(thumbnails: song.thumbnails, size: 48),
                        if (current)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                            child: const Icon(Icons.graphic_eq),
                          ),
                      ],
                    ),
                    title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artistNames, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => handler.skipToQueueItem(i),
                    onLongPress: () => showItemMenu(context, ref, song),
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.drag_handle)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LyricsTab extends ConsumerWidget {
  const _LyricsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);
    if (song == null) return const SizedBox.shrink();
    final lyrics = ref.watch(lyricsProvider(song.videoId));
    return switch (lyrics) {
      AsyncData(value: null) => const EmptyView(icon: Icons.lyrics_outlined, title: 'Lyrics not available'),
      AsyncData(:final value?) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        children: [
          Text(
            value.text,
            style: const TextStyle(
              fontSize: 20,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: YtmColors.textPrimary,
            ),
          ),
          if (value.source != null) ...[
            const SizedBox(height: 24),
            Text(value.source!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(lyricsProvider(song.videoId))),
      _ => const LoadingView(),
    };
  }
}

class _RelatedTab extends ConsumerWidget {
  const _RelatedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);
    if (song == null) return const SizedBox.shrink();
    final related = ref.watch(relatedProvider(song.videoId));
    return switch (related) {
      AsyncData(:final value) when value.isEmpty => const EmptyView(
        icon: Icons.explore_outlined,
        title: 'Nothing related',
      ),
      AsyncData(:final value) => ListView(
        padding: const EdgeInsets.only(bottom: 48),
        children: [for (final s in value) SectionView(section: s)],
      ),
      AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(relatedProvider(song.videoId))),
      _ => const LoadingView(),
    };
  }
}
