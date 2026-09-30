import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../providers.dart';
import '../../ui/theme/ytm_theme.dart';
import 'player_screen.dart';

bool _open = false;

/// Shows video mode's music video full screen, in landscape without system bars (docs/ui.md).
Future<void> openVideoFullscreen(BuildContext context) async {
  if (_open) return;
  _open = true;
  final navigator = Navigator.of(context, rootNavigator: true);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  try {
    await navigator.push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const _VideoFullscreen(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  } finally {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const []);
    _open = false;
  }
}

class _VideoFullscreen extends ConsumerStatefulWidget {
  const _VideoFullscreen();

  @override
  ConsumerState<_VideoFullscreen> createState() => _VideoFullscreenState();
}

class _VideoFullscreenState extends ConsumerState<_VideoFullscreen> {
  bool _controls = true;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  /// Controls fade out after 3 s while playing, as on YouTube.
  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted && (ref.read(playbackStateProvider).value?.playing ?? false)) setState(() => _controls = false);
    });
  }

  void _toggleControls() {
    setState(() => _controls = !_controls);
    if (_controls) _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    // Video mode ended (casting started, or the song has no video): leave full screen.
    ref.listen(videoModeProvider, (_, on) {
      if (!on) Navigator.of(context).pop();
    });
    final handler = ref.read(audioHandlerProvider);
    final song = ref.watch(currentSongProvider);
    final playing = ref.watch(playbackStateProvider).value?.playing ?? false;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ValueListenableBuilder(
              valueListenable: ref.watch(videoOutputProvider).controller,
              builder: (context, controller, _) => controller == null || !controller.value.isInitialized
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller)),
                    ),
            ),
            IgnorePointer(
              ignoring: !_controls,
              child: AnimatedOpacity(
                opacity: _controls ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Listener(
                  onPointerDown: (_) => _scheduleHide(),
                  child: ColoredBox(
                    color: const Color(0x80000000),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song?.title ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      Text(
                                        song?.artistNames ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium?.copyWith(color: YtmColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  iconSize: 40,
                                  icon: const Icon(Icons.skip_previous),
                                  onPressed: handler.skipToPrevious,
                                ),
                                const SizedBox(width: 40),
                                IconButton(
                                  iconSize: 56,
                                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                                  onPressed: playing ? handler.pause : handler.play,
                                ),
                                const SizedBox(width: 40),
                                IconButton(
                                  iconSize: 40,
                                  icon: const Icon(Icons.skip_next),
                                  onPressed: handler.skipToNext,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (song != null)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 16),
                                      child: SeekBar(song: song),
                                    ),
                                  )
                                else
                                  const Spacer(),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.fullscreen_exit),
                                  tooltip: 'Exit full screen',
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
