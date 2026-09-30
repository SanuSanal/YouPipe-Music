import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/error_log.dart';
import '../../data/updater.dart';
import '../../providers.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/item_menu.dart';
import '../../ui/widgets/states.dart';

/// Hidden page with this session's errors (docs/ui.md), opened by tapping the version in
/// Settings → About three times. Meant for debugging, so it's plain rather than YouTube Music-styled.
class ErrorLogScreen extends ConsumerWidget {
  const ErrorLogScreen({super.key});

  static String _time(DateTime t) => [t.hour, t.minute, t.second].map((n) => n.toString().padLeft(2, '0')).join(':');

  Future<void> _copy(BuildContext context, String text, String done) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) showSnack(context, done);
  }

  /// Opens GitHub's "new issue" page prefilled with [entries]; the user reviews and submits it there.
  Future<void> _report(WidgetRef ref, List<ErrorEntry> entries) async {
    final updater = ref.read(updaterProvider);
    final info = await ref
        .read(appInfoProvider.future)
        .catchError((Object _) => const AppInfo(versionName: '?', versionCode: 0, abis: []));
    final url = githubIssueUrl(
      repo: releasesRepo,
      entries: entries,
      appVersion: '${info.versionName} (${info.versionCode})',
      device: info.device,
    );
    await updater.openUrl(url.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ValueListenableBuilder(
      valueListenable: errorLog.entries,
      builder: (context, entries, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Error log'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              tooltip: 'Report on GitHub',
              onPressed: entries.isEmpty ? null : () => _report(ref, entries),
            ),
            IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              tooltip: 'Copy all',
              onPressed: entries.isEmpty
                  ? null
                  : () => _copy(context, entries.map((e) => e.toString()).join('\n\n'), 'Error log copied'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear',
              onPressed: entries.isEmpty ? null : errorLog.clear,
            ),
          ],
        ),
        body: entries.isEmpty
            ? const EmptyView(
                icon: Icons.check_circle_outline,
                title: 'No errors',
                message: 'Errors from this session show up here. They are kept in memory only.',
              )
            : ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final e = entries[i];
                  return ListTile(
                    title: Text(e.message, maxLines: 3, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${_time(e.time)} · ${e.source}${e.detail == null ? '' : ' · ${e.detail!.split('\n').first}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: YtmColors.textSecondary),
                    ),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('${_time(e.time)} · ${e.source}'),
                        content: SingleChildScrollView(child: SelectableText(e.toString())),
                        actions: [
                          TextButton(onPressed: () => _report(ref, [e]), child: const Text('Report')),
                          TextButton(
                            onPressed: () => _copy(context, e.toString(), 'Error copied'),
                            child: const Text('Copy'),
                          ),
                          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
