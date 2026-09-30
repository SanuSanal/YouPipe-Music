import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account.dart';

import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../innertube/models.dart';
import '../../player/audio_handler.dart';
import '../../player/cast.dart';
import '../../providers.dart';
import '../../ui/navigation.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/cast_button.dart';
import '../../ui/widgets/collection_header.dart';
import '../../ui/widgets/item_menu.dart';
import '../../ui/widgets/thumbnail.dart';
import 'queue_sheet.dart';
import 'video_fullscreen.dart';

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
              // Top bar: collapse, Song/Video toggle, Cast, menu.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 30), onPressed: onCollapse),
                    // Balances the Cast button so the toggle stays centred.
                    if (ref.watch(castStatusProvider).state != CastState.none) const SizedBox(width: 48),
                    const Spacer(),
                    _SongVideoToggle(song: song),
                    const Spacer(),
                    const CastButton(),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => showItemMenu(context, ref, song, inPlayer: true),
                    ),
                  ],
                ),
              ),
              const CastingLabel(),
              const Spacer(),
              if (ref.watch(videoModeProvider))
                _VideoView(song: song, width: size.width - 32)
              else
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
                    // Action pills sit on the left edge, like YouTube Music.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
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
                    ),
                    const SizedBox(height: 12),
                    SeekBar(song: song),
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

/// Song / Video, as in YouTube Music. Video is offered when the song has a music video and
/// nothing is being cast (docs/playback.md).
class _SongVideoToggle extends ConsumerWidget {
  const _SongVideoToggle({required this.song});

  final SongItem song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.read(audioHandlerProvider);
    final videoMode = ref.watch(videoModeProvider);
    final casting = ref.watch(castStatusProvider).connected;
    final hasVideo = ref.watch(musicVideoProvider(song.videoId)).value != null;
    final canVideo = videoMode || (hasVideo && !casting);

    Widget seg(String label, {required bool selected, required bool enabled, required VoidCallback onTap}) => InkWell(
      onTap: enabled && !selected ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0x33FFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: selected
                ? YtmColors.textPrimary
                : enabled
                ? YtmColors.textSecondary
                : YtmColors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('Song', selected: !videoMode, enabled: true, onTap: () => handler.setVideoMode(false)),
          seg('Video', selected: videoMode, enabled: canVideo, onTap: () => handler.setVideoMode(true)),
        ],
      ),
    );
  }
}

/// The music video in place of the artwork (16:9), with the artwork and a spinner until it's ready.
/// Tapping it shows the full screen button for a few seconds (it also shows when a video starts).
class _VideoView extends ConsumerStatefulWidget {
  const _VideoView({required this.song, required this.width});

  final SongItem song;
  final double width;

  @override
  ConsumerState<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends ConsumerState<_VideoView> {
  bool _overlay = false;
  Timer? _hide;
  VideoPlayerController? _shownFor;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _showOverlay() {
    _hide?.cancel();
    setState(() => _overlay = true);
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _overlay = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = width * 9 / 16;
    return ValueListenableBuilder(
      valueListenable: ref.watch(videoOutputProvider).controller,
      builder: (context, controller, _) {
        final ready = controller != null && controller.value.isInitialized;
        if (ready && !identical(controller, _shownFor)) {
          _shownFor = controller;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showOverlay();
          });
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: width,
            height: height,
            child: ColoredBox(
              color: Colors.black,
              child: !ready
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Opacity(
                          opacity: 0.35,
                          child: YtImage(thumbnails: widget.song.thumbnails, size: width),
                        ),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _overlay ? setState(() => _overlay = false) : _showOverlay(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio: controller.value.aspectRatio,
                              child: VideoPlayer(controller),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: IgnorePointer(
                              ignoring: !_overlay,
                              child: AnimatedOpacity(
                                opacity: _overlay ? 1 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: IconButton(
                                  icon: const Icon(Icons.fullscreen, size: 28),
                                  tooltip: 'Full screen',
                                  style: IconButton.styleFrom(backgroundColor: const Color(0x66000000)),
                                  onPressed: () {
                                    setState(() => _overlay = false);
                                    openVideoFullscreen(context);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
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

/// The player's seek bar with elapsed and total time; also used by the full-screen video.
class SeekBar extends ConsumerStatefulWidget {
  const SeekBar({super.key, required this.song});

  final SongItem song;

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar> {
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
