import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/thumbnail.dart';

/// Thin progress line + art, title/artist, play/pause and next (sits above the bottom nav).
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, required this.song, required this.onTap});

  final SongItem song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.read(audioHandlerProvider);
    final state = ref.watch(playbackStateProvider).value;
    final playing = state?.playing ?? false;
    final busy =
        state?.processingState == AudioProcessingState.loading ||
        state?.processingState == AudioProcessingState.buffering;
    final error = state?.processingState == AudioProcessingState.error;
    final theme = Theme.of(context);

    return Material(
      color: YtmColors.surface,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: YtmSizes.miniPlayerHeight,
          child: Column(
            children: [
              SongProgressBar(song: song, height: 2),
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    YtImage(thumbnails: song.thumbnails, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            error ? (state?.errorMessage ?? "Can't play this song") : song.artistNames,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: error ? YtmColors.brandRed : null),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: busy
                          ? const Center(
                              child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : IconButton(
                              // After a failure Play reloads the song, so it shows as Reload.
                              icon: Icon(
                                error
                                    ? Icons.refresh
                                    : playing
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: 30,
                              ),
                              onPressed: playing ? handler.pause : handler.play,
                            ),
                    ),
                    IconButton(icon: const Icon(Icons.skip_next, size: 28), onPressed: handler.skipToNext),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Playback progress as a plain bar (mini player) — the full player uses a seekable slider.
class SongProgressBar extends ConsumerWidget {
  const SongProgressBar({super.key, required this.song, this.height = 2});

  final SongItem song;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final total = ref.read(audioHandlerProvider).duration ?? song.duration ?? Duration.zero;
    final value = total.inMilliseconds == 0 ? 0.0 : pos.inMilliseconds / total.inMilliseconds;
    return LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      minHeight: height,
      color: YtmColors.textPrimary,
      backgroundColor: YtmColors.progressTrack,
    );
  }
}
