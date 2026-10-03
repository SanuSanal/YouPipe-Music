import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/player/mini_player.dart';
import '../../features/player/player_screen.dart';
import '../../features/update/update_sheet.dart';
import '../../innertube/models.dart';
import '../../player/audio_handler.dart' show PlayerNotice;
import '../../providers.dart';
import '../navigation.dart';
import '../widgets/item_menu.dart' show showSnack;
import '../theme/ytm_theme.dart';

/// Bottom navigation + the player panel that expands from the mini player to full screen.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with SingleTickerProviderStateMixin {
  late final _panel = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  StreamSubscription<PlayerNotice>? _notices;

  @override
  void initState() {
    super.initState();
    _notices = ref.read(audioHandlerProvider).notices.stream.listen((notice) {
      if (!mounted) return;
      showSnack(context, switch (notice) {
        PlayerNotice.noVideo => 'No video for this song',
        PlayerNotice.videoUnavailable => "Video isn't available. Playing the song",
        PlayerNotice.songUnavailable => "This song isn't available",
      });
    });
    // Look for a new release once the app has settled, so the check doesn't compete with startup.
    Future.delayed(const Duration(seconds: 3), () async {
      final update = await ref.read(updateProvider.notifier).checkOnLaunch();
      if (update != null && mounted) unawaited(showUpdateSheet(context, update));
    });
  }

  @override
  void dispose() {
    _notices?.cancel();
    _panel.dispose();
    super.dispose();
  }

  void _settle(double velocity) {
    final expand = velocity < -300 || (velocity.abs() <= 300 && _panel.value > 0.5);
    ref.read(playerPanelProvider.notifier).set(expand);
    _panel.animateTo(expand ? 1 : 0, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playerPanelProvider, (_, expanded) {
      _panel.animateTo(expanded ? 1 : 0, curve: Curves.easeOutCubic);
    });
    // Record plays in the local history.
    ref.listen(currentSongProvider, (prev, next) {
      if (next != null && prev?.videoId != next.videoId && ref.read(settingsProvider).saveHistory) {
        ref.read(libraryProvider).addToHistory(next);
      }
    });

    final song = ref.watch(currentSongProvider);
    final media = MediaQuery.of(context);
    final navHeight = YtmSizes.navBarHeight + media.padding.bottom;
    final miniHeight = song == null ? 0.0 : YtmSizes.miniPlayerHeight;

    // Back: collapse the expanded player first (before the router pops pages), then go to Home, then exit.
    return BackButtonListener(
      onBackButtonPressed: () async {
        // A sheet/dialog above the shell (e.g. Up next) closes first.
        if (_panel.value == 0 || ModalRoute.of(context)?.isCurrent == false) return false;
        ref.read(playerPanelProvider.notifier).collapse();
        return true;
      },
      child: PopScope(
        canPop: widget.navigationShell.currentIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.navigationShell.goBranch(0);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final fullHeight = constraints.maxHeight;
              return AnimatedBuilder(
                animation: _panel,
                builder: (context, _) {
                  final t = _panel.value;
                  return Stack(
                    children: [
                      Positioned.fill(bottom: navHeight + miniHeight, child: widget.navigationShell),
                      if (song != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: lerpDouble(navHeight, 0, t),
                          height: lerpDouble(miniHeight, fullHeight, t),
                          child: GestureDetector(
                            onVerticalDragUpdate: (d) => _panel.value -= d.primaryDelta! / fullHeight,
                            onVerticalDragEnd: (d) => _settle(d.primaryVelocity ?? 0),
                            child: _PanelContent(
                              song: song,
                              t: t,
                              fullHeight: fullHeight,
                              onExpand: () => ref.read(playerPanelProvider.notifier).expand(),
                              onCollapse: () => ref.read(playerPanelProvider.notifier).collapse(),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: -navHeight * t,
                        height: navHeight,
                        child: _BottomNav(
                          index: widget.navigationShell.currentIndex,
                          onTap: (i) => widget.navigationShell.goBranch(
                            i,
                            initialLocation: i == widget.navigationShell.currentIndex,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({
    required this.song,
    required this.t,
    required this.fullHeight,
    required this.onExpand,
    required this.onCollapse,
  });

  final SongItem song;
  final double t;
  final double fullHeight;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final miniOpacity = (1 - t * 4).clamp(0.0, 1.0);
    final fullOpacity = ((t - 0.15) / 0.85).clamp(0.0, 1.0);
    return ClipRect(
      child: ColoredBox(
        color: Color.lerp(YtmColors.surface, YtmColors.background, t)!,
        child: Stack(
          children: [
            if (fullOpacity > 0)
              Opacity(
                opacity: fullOpacity,
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: fullHeight,
                  maxHeight: fullHeight,
                  child: PlayerScreen(song: song, onCollapse: onCollapse),
                ),
              ),
            if (miniOpacity > 0)
              IgnorePointer(
                ignoring: t > 0.1,
                child: Opacity(
                  opacity: miniOpacity,
                  child: MiniPlayer(song: song, onTap: onExpand),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, Icons.home_filled, 'Home'),
      (Icons.explore_outlined, Icons.explore, 'Explore'),
      (Icons.library_music_outlined, Icons.library_music, 'Library'),
    ];
    return Material(
      color: YtmColors.navBar,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final (i, (icon, selectedIcon, label)) in items.indexed)
              Expanded(
                child: InkResponse(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(i == index ? selectedIcon : icon, color: YtmColors.textPrimary, size: 26),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: i == index ? FontWeight.w600 : FontWeight.w400,
                          color: i == index ? YtmColors.textPrimary : YtmColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
