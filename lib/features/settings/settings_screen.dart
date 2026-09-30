import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../data/account.dart';
import '../../data/stream_resolver.dart';
import '../../data/updater.dart';
import '../../player/lock_screen.dart';
import '../update/update_sheet.dart';
import '../../ui/widgets/thumbnail.dart';
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

    const audioQualities = {
      AudioQuality.high: 'High',
      AudioQuality.normal: 'Normal',
      AudioQuality.low: 'Low (saves data)',
    };
    const videoQualities = {
      VideoQuality.auto: 'Auto (recommended)',
      VideoQuality.high: 'Higher picture quality',
      VideoQuality.dataSaver: 'Data saver',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _Header('Account'),
          const _AccountTile(),
          const _Header('Playback'),
          ListTile(
            leading: const Icon(Icons.high_quality_outlined, color: YtmColors.textPrimary),
            title: const Text('Audio quality'),
            subtitle: Text(audioQualities[s.quality]!),
            onTap: () =>
                pick('Audio quality', audioQualities, s.quality, (v) => controller.update(s.copyWith(quality: v))),
          ),
          ListTile(
            leading: const Icon(Icons.hd_outlined, color: YtmColors.textPrimary),
            title: const Text('Video quality'),
            subtitle: Text(videoQualities[s.videoQuality]!),
            onTap: () => pick(
              'Video quality',
              videoQualities,
              s.videoQuality,
              (v) => controller.update(s.copyWith(videoQuality: v)),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.content_cut, color: YtmColors.textPrimary),
            title: const Text('Skip non-music sections'),
            subtitle: const Text('Skips intros, skits and outros in music videos (SponsorBlock)'),
            value: s.skipNonMusic,
            activeTrackColor: YtmColors.brandRed,
            onChanged: (v) => controller.update(s.copyWith(skipNonMusic: v)),
          ),
          const _LockScreenTile(),
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
          ListTile(
            leading: const Icon(Icons.info_outline, color: YtmColors.textPrimary),
            title: const Text('YouPipe Music'),
            subtitle: Text(
              'Version ${ref.watch(appInfoProvider).value?.versionName ?? '…'}\n'
              'Ad-free YouTube Music client. Streams via NewPipeExtractor.',
            ),
            isThreeLine: true,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.update, color: YtmColors.textPrimary),
            title: const Text('Check for updates automatically'),
            subtitle: const Text('Looks for a new version on GitHub when the app opens'),
            value: s.autoUpdateCheck,
            activeTrackColor: YtmColors.brandRed,
            onChanged: (v) => controller.update(s.copyWith(autoUpdateCheck: v)),
          ),
          const _CheckForUpdatesTile(),
        ],
      ),
    );
  }
}

/// "Lock screen player" needs "Display over other apps", granted on a system page; the setting is
/// only saved once the user comes back with it granted.
class _LockScreenTile extends ConsumerStatefulWidget {
  const _LockScreenTile();

  @override
  ConsumerState<_LockScreenTile> createState() => _LockScreenTileState();
}

class _LockScreenTileState extends ConsumerState<_LockScreenTile> with WidgetsBindingObserver {
  bool _granted = true;
  bool _awaitingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final granted = await LockScreenPlayer.canShow();
    if (!mounted) return;
    setState(() => _granted = granted);
    if (_awaitingPermission && granted) {
      final controller = ref.read(settingsProvider.notifier);
      await controller.update(ref.read(settingsProvider).copyWith(lockScreenPlayer: true));
    }
    _awaitingPermission = false;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    return SwitchListTile(
      secondary: const Icon(Icons.screen_lock_portrait_outlined, color: YtmColors.textPrimary),
      title: const Text('Lock screen player'),
      subtitle: Text(
        s.lockScreenPlayer && !_granted
            ? 'Needs "Display over other apps" to show'
            : 'Full-screen artwork and controls on the lock screen',
      ),
      value: s.lockScreenPlayer,
      activeTrackColor: YtmColors.brandRed,
      onChanged: (v) {
        if (!v || _granted) {
          controller.update(s.copyWith(lockScreenPlayer: v));
        } else {
          _awaitingPermission = true;
          LockScreenPlayer.requestPermission();
        }
      },
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value ?? const AuthState();
    if (!auth.signedIn) {
      return ListTile(
        leading: const Icon(Icons.account_circle_outlined, color: YtmColors.textPrimary),
        title: const Text('Sign in to YouTube Music'),
        subtitle: const Text('Your library, likes and personalised recommendations'),
        onTap: () async {
          final ok = await context.push<bool>('/login');
          if (ok == true && context.mounted) showSnack(context, 'Signed in');
        },
      );
    }
    final account = auth.account;
    return Column(
      children: [
        ListTile(
          leading: account == null || account.photos.isEmpty
              ? const Icon(Icons.account_circle, color: YtmColors.textPrimary, size: 40)
              : YtImage(thumbnails: account.photos, size: 40, circle: true),
          title: Text(account?.name ?? 'Signed in'),
          subtitle: Text(account?.email ?? account?.handle ?? 'YouTube Music account'),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: YtmColors.textPrimary),
          title: const Text('Sign out'),
          onTap: () async {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) showSnack(context, 'Signed out');
          },
        ),
      ],
    );
  }
}

class _CheckForUpdatesTile extends ConsumerWidget {
  const _CheckForUpdatesTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);
    final subtitle = switch (state) {
      UpdateChecking() => 'Checking…',
      UpdateAvailable(:final update) => 'Version ${update.version} is available',
      UpdateDownloading(:final update, :final progress) =>
        'Downloading ${update.version}${progress == null ? '' : ' (${(progress * 100).round()}%)'}',
      UpdateInstalling(:final update) => 'Installing ${update.version}…',
      UpdateFailed() => "Couldn't update. Tap to see why",
      UpdateIdle() => null,
    };
    return ListTile(
      leading: const Icon(Icons.system_update_outlined, color: YtmColors.textPrimary),
      title: const Text('Check for updates'),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: state is UpdateChecking
          ? null
          : () async {
              final current = switch (state) {
                UpdateAvailable(:final update) ||
                UpdateDownloading(:final update) ||
                UpdateInstalling(:final update) => update,
                UpdateFailed(:final update) => update,
                _ => null,
              };
              try {
                final update = current ?? await ref.read(updateProvider.notifier).checkNow();
                if (!context.mounted) return;
                if (update == null) {
                  showSnack(context, "You're on the latest version");
                } else {
                  await showUpdateSheet(context, update);
                }
              } on UpdateException catch (e) {
                if (context.mounted) {
                  showSnack(context, e.code == 'NO_APK' ? 'No update for this device' : "Couldn't check for updates");
                }
              }
            },
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
