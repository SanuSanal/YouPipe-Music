import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../providers.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/item_menu.dart' show showSnack;

String _remaining(DateTime endsAt) {
  final d = endsAt.difference(DateTime.now());
  if (d.isNegative) return 'Stopping…';
  final m = d.inMinutes;
  return m >= 1 ? '$m min left' : '${d.inSeconds}s left';
}

/// Subtitle for the "Sleep timer" menu entry.
String sleepTimerLabel(WidgetRef ref) {
  final t = ref.watch(sleepTimerProvider).value;
  if (t == null) return 'Off';
  if (t.endOfSong) return 'End of song';
  return _remaining(t.endsAt!);
}

Future<void> showSleepTimerSheet(BuildContext context, WidgetRef ref) {
  final handler = ref.read(audioHandlerProvider);
  const options = [5, 10, 15, 30, 45, 60];
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (sheet) => SafeArea(
      child: Consumer(
        builder: (sheet, ref, _) {
          final active = ref.watch(sleepTimerProvider).value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Sleep timer', style: Theme.of(sheet).textTheme.titleLarge),
              ),
              for (final m in options)
                ListTile(
                  title: Text('$m minutes'),
                  onTap: () {
                    handler.setSleepTimer(Duration(minutes: m));
                    Navigator.of(sheet).pop();
                    showSnack(context, 'Sleep timer set for $m minutes');
                  },
                ),
              ListTile(
                title: const Text('End of song'),
                trailing: active?.endOfSong == true ? const Icon(Icons.check) : null,
                onTap: () {
                  handler.sleepAtEndOfSong();
                  Navigator.of(sheet).pop();
                  showSnack(context, 'Playback will stop at the end of this song');
                },
              ),
              if (active != null)
                ListTile(
                  leading: const Icon(Icons.timer_off_outlined, color: YtmColors.textPrimary),
                  title: const Text('Turn off timer'),
                  subtitle: Text(active.endOfSong ? 'End of song' : _remaining(active.endsAt!)),
                  onTap: () {
                    handler.cancelSleepTimer();
                    Navigator.of(sheet).pop();
                  },
                ),
            ],
          );
        },
      ),
    ),
  );
}

Future<void> showSpeedSheet(BuildContext context, WidgetRef ref) {
  final handler = ref.read(audioHandlerProvider);
  const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (sheet) => SafeArea(
      child: Consumer(
        builder: (sheet, ref, _) {
          final current = ref.watch(speedProvider).value ?? 1.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Playback speed', style: Theme.of(sheet).textTheme.titleLarge),
              ),
              for (final s in speeds)
                ListTile(
                  title: Text(s == 1.0 ? 'Normal' : '${s}x'),
                  trailing: (current - s).abs() < 0.01 ? const Icon(Icons.check) : null,
                  onTap: () {
                    handler.setSpeed(s);
                    Navigator.of(sheet).pop();
                  },
                ),
            ],
          );
        },
      ),
    ),
  );
}

/// Presets as a gain curve over frequency (Hz → dB), so they fit any band layout.
final Map<String, double Function(double hz)> eqPresets = {
  'Flat': (_) => 0,
  'Bass boost': (hz) => hz < 150
      ? 6
      : hz < 400
      ? 3
      : 0,
  'Bass reducer': (hz) => hz < 150
      ? -6
      : hz < 400
      ? -3
      : 0,
  'Vocal': (hz) => hz < 250
      ? -2
      : hz < 4000
      ? 4
      : 1,
  'Treble boost': (hz) => hz > 6000
      ? 6
      : hz > 2500
      ? 3
      : 0,
  'Rock': (hz) => hz < 250
      ? 5
      : hz < 2000
      ? -1
      : 4,
  'Pop': (hz) => hz < 250
      ? -1
      : hz < 4000
      ? 3
      : 1,
  'Electronic': (hz) => hz < 250
      ? 5
      : hz < 2000
      ? 0
      : 4,
};

Future<void> showEqualizerSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => const SafeArea(child: _EqualizerSheet()),
);

class _EqualizerSheet extends ConsumerWidget {
  const _EqualizerSheet();

  static String _hz(double f) =>
      f >= 1000 ? '${(f / 1000).toStringAsFixed(f >= 10000 ? 0 : 1)}k' : f.round().toString();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fx = ref.watch(audioEffectsProvider);
    final controller = ref.read(audioEffectsProvider.notifier);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: FutureBuilder<AndroidEqualizerParameters>(
        future: ref.read(audioHandlerProvider).equalizer.parameters,
        builder: (context, snap) {
          final params = snap.data;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Equalizer', style: theme.textTheme.titleLarge)),
                  Switch(value: fx.eqEnabled, activeTrackColor: YtmColors.brandRed, onChanged: controller.setEnabled),
                ],
              ),
              if (params == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Start playing a song to adjust the equalizer.'),
                )
              else ...[
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final name in eqPresets.keys)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(name),
                            selected: fx.preset == name,
                            showCheckmark: false,
                            selectedColor: YtmColors.chipSelected,
                            backgroundColor: YtmColors.chip,
                            side: BorderSide.none,
                            labelStyle: TextStyle(
                              color: fx.preset == name ? Colors.black : YtmColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            onSelected: (_) {
                              final curve = eqPresets[name]!;
                              final gains = [
                                for (final b in params.bands)
                                  curve(b.centerFrequency).clamp(params.minDecibels, params.maxDecibels).toDouble(),
                              ];
                              if (!fx.eqEnabled) controller.setEnabled(true);
                              controller.setGains(gains, preset: name);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: Row(
                    children: [
                      for (final band in params.bands)
                        Expanded(
                          child: StreamBuilder<double>(
                            stream: band.gainStream,
                            builder: (context, gainSnap) {
                              final gain = gainSnap.data ?? band.gain;
                              return Column(
                                children: [
                                  Text(
                                    '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(0)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Expanded(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: Slider(
                                        value: gain.clamp(params.minDecibels, params.maxDecibels),
                                        min: params.minDecibels,
                                        max: params.maxDecibels,
                                        activeColor: fx.eqEnabled ? YtmColors.brandRed : YtmColors.textSecondary,
                                        onChanged: (v) => band.setGain(v),
                                        onChangeEnd: (_) {
                                          if (!fx.eqEnabled) controller.setEnabled(true);
                                          controller.setGains([for (final b in params.bands) b.gain]);
                                        },
                                      ),
                                    ),
                                  ),
                                  Text(_hz(band.centerFrequency), style: theme.textTheme.bodySmall),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Loudness boost', style: theme.textTheme.titleSmall),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: fx.loudnessDb,
                      max: 10,
                      divisions: 10,
                      activeColor: YtmColors.brandRed,
                      onChanged: (v) => controller.setLoudness(v),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(fx.loudnessDb == 0 ? 'Off' : '+${fx.loudnessDb.round()} dB', textAlign: TextAlign.end),
                  ),
                ],
              ),
              Text(
                'Boosting can distort loud songs.',
                style: theme.textTheme.bodySmall?.copyWith(color: YtmColors.textSecondary.withValues(alpha: 0.8)),
              ),
              SizedBox(height: math.max(0, MediaQuery.viewInsetsOf(context).bottom)),
            ],
          );
        },
      ),
    );
  }
}
