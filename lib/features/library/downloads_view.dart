import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart' show DownloadStatus;
import '../../data/download_manager.dart';
import '../../providers.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/item_tiles.dart';
import '../../ui/widgets/states.dart';

String _size(int bytes) =>
    bytes >= 1024 * 1024 ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB' : '${(bytes / 1024).round()} KB';

/// Library > Downloads: finished songs play offline; in-progress ones show progress; failed ones can retry.
class DownloadsSliver extends ConsumerWidget {
  const DownloadsSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(downloadsProvider).value ?? const <DownloadEntry>[];
    if (entries.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(
          icon: Icons.download_outlined,
          title: 'No downloads yet',
          message: 'Use "Download" on any song, album or playlist to listen offline.',
        ),
      );
    }
    final done = [
      for (final e in entries)
        if (e.row.status == DownloadStatus.done) e.song,
    ];
    final manager = ref.read(downloadManagerProvider);
    final totalBytes = entries.fold<int>(0, (sum, e) => sum + e.row.sizeBytes);

    return SliverList.builder(
      itemCount: entries.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(YtmSizes.pagePadding, 4, YtmSizes.pagePadding, 8),
            child: Text(
              '${songCount(done.length)} • ${_size(totalBytes)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        final e = entries[i - 1];
        final Widget? trailing = switch (e.row.status) {
          DownloadStatus.done => null,
          DownloadStatus.failed => IconButton(
            tooltip: 'Retry',
            icon: const Icon(Icons.refresh, color: YtmColors.brandRed),
            onPressed: () => manager.retry(e.song),
          ),
          _ => SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: e.row.status == DownloadStatus.queued || e.progress == 0 ? null : e.progress,
              strokeWidth: 2.5,
            ),
          ),
        };
        return ResponsiveListTile(
          item: e.song,
          subtitle: switch (e.row.status) {
            DownloadStatus.failed => 'Download failed',
            DownloadStatus.queued => 'Waiting…',
            DownloadStatus.downloading => 'Downloading ${(e.progress * 100).round()}%',
            DownloadStatus.done => '${e.song.artistNames} • ${_size(e.row.sizeBytes)}',
          },
          trailing: trailing,
          onTap: e.row.status == DownloadStatus.done
              ? () => ref
                    .read(playerActionsProvider)
                    .playList(done, index: done.indexWhere((s) => s.videoId == e.song.videoId), title: 'Downloads')
              : null,
        );
      },
    );
  }
}
