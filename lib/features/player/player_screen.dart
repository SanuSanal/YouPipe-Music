import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account.dart';

import 'package:share_plus/share_plus.dart';

import '../../innertube/models.dart';
import '../../player/audio_handler.dart';
import '../../providers.dart';
import '../../ui/navigation.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/collection_header.dart';
import '../../ui/widgets/item_menu.dart';
import '../../ui/widgets/thumbnail.dart';
import 'queue_sheet.dart';

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// The full-screen "Now playing" view.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key, required this.song, required this.onCollapse});

  final SongItem song;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final artSize = (size.width - 48).clamp(200.0, size.height * 0.42);
    final liked = ref.watch(isLikedProvider(song.videoId)).value ?? false;

    return ArtworkTint(
      url: song.thumbnails.best(120),
      builder: (context, tint) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tint, Color.lerp(tint, YtmColors.background, 0.75)!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: collapse, Song/Video toggle, menu.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 30), onPressed: onCollapse),
                    const Spacer(),
                    const _SongVideoToggle(),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => showItemMenu(context, ref, song, inPlayer: true),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Hero(
                tag: 'player-art',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 30, offset: Offset(0, 10))],
                  ),
                  child: YtImage(thumbnails: song.thumbnails, size: artSize, radius: 8),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () {
                                  final artist = song.artists.where((a) => a.id != null).firstOrNull;
                                  if (artist != null) openArtist(context, ref, artist.id!);
                                },
                                child: Text(
                                  song.artistNames,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(color: YtmColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _Pill(
                            icon: liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            label: liked ? 'Liked' : 'Like',
                            onTap: () => ref.read(accountActionsProvider).setLiked(song, !liked),
                          ),
                          _Pill(
                            icon: Icons.playlist_add,
                            label: 'Save',
                            onTap: () => showSaveToPlaylist(context, ref, [song]),
                          ),
                          _Pill(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            onTap: () => SharePlus.instance.share(ShareParams(text: shareUrl(song))),
                          ),
                          if (song.album != null)
                            _Pill(
                              icon: Icons.album_outlined,
                              label: 'Album',
                              onTap: () => openAlbum(context, ref, song.album!.id),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SeekBar(song: song),
                    const _Controls(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const QueueTabsBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongVideoToggle extends StatelessWidget {
  const _SongVideoToggle();

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool selected) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0x33FFFFFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: selected ? YtmColors.textPrimary : YtmColors.textSecondary,
        ),
      ),
    );
    return Tooltip(
      message: 'Video mode is coming later',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [seg('Song', true), seg('Video', false)]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Material(
      color: const Color(0x1AFFFFFF),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SeekBar extends ConsumerStatefulWidget {
  const _SeekBar({required this.song});

  final SongItem song;

  @override
  ConsumerState<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<_SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final handler = ref.read(audioHandlerProvider);
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final total = handler.duration ?? widget.song.duration ?? Duration.zero;
    final max = total.inMilliseconds.toDouble();
    final value = (_dragValue ?? pos.inMilliseconds.toDouble()).clamp(0.0, max <= 0 ? 1.0 : max);
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 3),
          child: Slider(
            value: value,
            max: max <= 0 ? 1 : max,
            padding: EdgeInsets.zero,
            onChanged: max <= 0 ? null : (v) => setState(() => _dragValue = v),
            onChangeEnd: (v) {
              handler.seek(Duration(milliseconds: v.round()));
              setState(() => _dragValue = null);
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatDuration(Duration(milliseconds: value.round())), style: style),
            Text(formatDuration(total), style: style),
          ],
        ),
      ],
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.read(audioHandlerProvider);
    final queue = ref.watch(queueStateProvider).value ?? const QueueState();
    final state = ref.watch(playbackStateProvider).value;
    final playing = state?.playing ?? false;
    final busy =
        state?.processingState == AudioProcessingState.loading ||
        state?.processingState == AudioProcessingState.buffering;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.shuffle, color: queue.shuffle ? YtmColors.textPrimary : YtmColors.textSecondary),
          onPressed: handler.toggleShuffle,
        ),
        IconButton(iconSize: 40, icon: const Icon(Icons.skip_previous), onPressed: handler.skipToPrevious),
        SizedBox(
          width: 76,
          height: 76,
          child: FilledButton(
            onPressed: playing ? handler.pause : handler.play,
            style: FilledButton.styleFrom(
              backgroundColor: YtmColors.textPrimary,
              foregroundColor: Colors.black,
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: busy
                ? const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                  )
                : Icon(playing ? Icons.pause : Icons.play_arrow, size: 44),
          ),
        ),
        IconButton(iconSize: 40, icon: const Icon(Icons.skip_next), onPressed: handler.skipToNext),
        IconButton(
          icon: Icon(
            queue.repeat == QueueRepeatMode.one ? Icons.repeat_one : Icons.repeat,
            color: queue.repeat == QueueRepeatMode.off ? YtmColors.textSecondary : YtmColors.textPrimary,
          ),
          onPressed: handler.cycleRepeat,
        ),
      ],
    );
  }
}
