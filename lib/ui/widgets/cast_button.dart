import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/cast.dart';
import '../../providers.dart';
import '../theme/ytm_theme.dart';

/// The Cast button (docs/cast.md). Like YouTube Music, it only shows when there's a device to cast
/// to or a session is live. It opens [showCastSheet].
class CastButton extends ConsumerWidget {
  const CastButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(castStatusProvider);
    if (status.state == CastState.none) return const SizedBox.shrink();
    return IconButton(
      tooltip: status.connected ? 'Casting to ${status.device ?? 'a device'}' : 'Cast',
      icon: Icon(status.connected ? Icons.cast_connected : Icons.cast, color: YtmColors.textPrimary),
      onPressed: () => showCastSheet(context),
    );
  }
}

/// "Playing on `device`" under the full player's top bar while casting.
class CastingLabel extends ConsumerWidget {
  const CastingLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(castStatusProvider);
    if (!status.connected) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cast_connected, size: 16, color: YtmColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Playing on ${status.device ?? 'a Cast device'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// The device picker: Chromecasts and DLNA TVs/speakers together, with volume and "Stop casting"
/// while connected.
Future<void> showCastSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => const _CastSheet(),
);

class _CastSheet extends ConsumerStatefulWidget {
  const _CastSheet();

  @override
  ConsumerState<_CastSheet> createState() => _CastSheetState();
}

class _CastSheetState extends ConsumerState<_CastSheet> {
  @override
  void initState() {
    super.initState();
    ref.read(castControllerProvider).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cast = ref.watch(castControllerProvider);
    final status = ref.watch(castStatusProvider);
    final theme = Theme.of(context);
    return SafeArea(
      child: ValueListenableBuilder(
        valueListenable: cast.devices,
        builder: (context, devices, _) => ValueListenableBuilder(
          valueListenable: cast.connectedDevice,
          builder: (context, connected, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(status.connected ? 'Casting' : 'Cast to a device', style: theme.textTheme.titleMedium),
              ),
              if (status.connected && status.volumeControl) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_down, color: YtmColors.textSecondary),
                      Expanded(
                        child: Slider(value: status.volume.clamp(0.0, 1.0), onChanged: cast.setVolume),
                      ),
                      const Icon(Icons.volume_up, color: YtmColors.textSecondary),
                    ],
                  ),
                ),
              ],
              for (final device in devices)
                ListTile(
                  leading: Icon(
                    device.kind == CastKind.chromecast ? Icons.cast : Icons.tv,
                    color: device == connected ? YtmColors.brandRed : YtmColors.textPrimary,
                  ),
                  title: Text(device.name),
                  subtitle: Text(
                    device == connected
                        ? (status.connected ? 'Connected' : 'Connecting…')
                        : device.kind == CastKind.chromecast
                        ? 'Chromecast'
                        : 'Smart TV or speaker (DLNA)',
                  ),
                  trailing: device == connected && status.state == CastState.connecting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                  onTap: device == connected
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          cast.connect(device);
                        },
                ),
              if (devices.isEmpty)
                const ListTile(
                  leading: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  title: Text('Looking for devices on your Wi-Fi…'),
                ),
              if (connected != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        cast.disconnect();
                      },
                      child: const Text('Stop casting'),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
