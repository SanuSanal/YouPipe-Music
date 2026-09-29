import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/stream_resolver.dart';
import '../../providers.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/item_menu.dart';

const _regions = {
  'US': 'United States',
  'GB': 'United Kingdom',
  'IN': 'India',
  'IE': 'Ireland',
  'CA': 'Canada',
  'AU': 'Australia',
  'DE': 'Germany',
  'FR': 'France',
  'ES': 'Spain',
  'IT': 'Italy',
  'BR': 'Brazil',
  'MX': 'Mexico',
  'JP': 'Japan',
  'KR': 'South Korea',
  'ID': 'Indonesia',
  'PH': 'Philippines',
  'NG': 'Nigeria',
  'ZA': 'South Africa',
  'AE': 'United Arab Emirates',
  'TR': 'Türkiye',
  'RU': 'Russia',
  'VN': 'Vietnam',
};
const _languages = {
  'en': 'English',
  'hi': 'Hindi',
  'ml': 'Malayalam',
  'ta': 'Tamil',
  'te': 'Telugu',
  'es': 'Spanish',
  'pt': 'Portuguese',
  'fr': 'French',
  'de': 'German',
  'it': 'Italian',
  'ja': 'Japanese',
  'ko': 'Korean',
  'id': 'Indonesian',
  'tr': 'Turkish',
  'ru': 'Russian',
  'vi': 'Vietnamese',
  'ar': 'Arabic',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    Future<void> pick<T>(String title, Map<T, String> options, T current, void Function(T) onPick) async {
      final value = await showModalBottomSheet<T>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        builder: (sheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(title, style: Theme.of(sheet).textTheme.titleLarge),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final e in options.entries)
                        ListTile(
                          title: Text(e.value),
                          trailing: e.key == current ? const Icon(Icons.check) : null,
                          onTap: () => Navigator.of(sheet).pop(e.key),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (value != null) onPick(value);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _Header('Playback'),
          ListTile(
            leading: const Icon(Icons.high_quality_outlined, color: YtmColors.textPrimary),
            title: const Text('Audio quality'),
            subtitle: Text(s.quality == AudioQuality.high ? 'High' : 'Low (saves data)'),
            onTap: () => pick(
              'Audio quality',
              {AudioQuality.high: 'High', AudioQuality.low: 'Low (saves data)'},
              s.quality,
              (v) => controller.update(s.copyWith(quality: v)),
            ),
          ),
          const _Header('Content'),
          ListTile(
            leading: const Icon(Icons.public, color: YtmColors.textPrimary),
            title: const Text('Location'),
            subtitle: Text(_regions[s.gl] ?? s.gl),
            onTap: () => pick('Location', _regions, s.gl, (v) {
              controller.update(s.copyWith(gl: v));
              ref.invalidate(homeProvider);
              ref.invalidate(exploreProvider);
            }),
          ),
          ListTile(
            leading: const Icon(Icons.translate, color: YtmColors.textPrimary),
            title: const Text('Language'),
            subtitle: Text(_languages[s.hl] ?? s.hl),
            onTap: () => pick('Language', _languages, s.hl, (v) {
              controller.update(s.copyWith(hl: v));
              ref.invalidate(homeProvider);
              ref.invalidate(exploreProvider);
            }),
          ),
          const _Header('Privacy & storage'),
          SwitchListTile(
            secondary: const Icon(Icons.history, color: YtmColors.textPrimary),
            title: const Text('Save listening history'),
            value: s.saveHistory,
            activeTrackColor: YtmColors.brandRed,
            onChanged: (v) => controller.update(s.copyWith(saveHistory: v)),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: YtmColors.textPrimary),
            title: const Text('Clear listening history'),
            onTap: () async {
              await ref.read(libraryProvider).clearHistory();
              if (context.mounted) showSnack(context, 'History cleared');
            },
          ),
          ListTile(
            leading: const Icon(Icons.image_not_supported_outlined, color: YtmColors.textPrimary),
            title: const Text('Clear image cache'),
            onTap: () async {
              await DefaultCacheManager().emptyCache();
              PaintingBinding.instance.imageCache.clear();
              if (context.mounted) showSnack(context, 'Image cache cleared');
            },
          ),
          const _Header('About'),
          const ListTile(
            leading: Icon(Icons.info_outline, color: YtmColors.textPrimary),
            title: Text('YouPipe Music'),
            subtitle: Text('Ad-free YouTube Music client. Streams via NewPipeExtractor.'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: YtmColors.brandRed)),
  );
}
