import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lyrics/lrc.dart';
import '../../data/lyrics/lyrics_service.dart';
import '../../providers.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/states.dart';

/// Lyrics tab: time-synced lines when available (auto-scroll, tap to seek), plain text otherwise.
class LyricsView extends ConsumerWidget {
  const LyricsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);
    if (song == null) return const SizedBox.shrink();
    final lyrics = ref.watch(songLyricsProvider(song));
    return switch (lyrics) {
      AsyncData(value: null) => const EmptyView(icon: Icons.lyrics_outlined, title: 'Lyrics not available'),
      AsyncData(:final value?) when value.isSynced => _SyncedLyrics(key: ValueKey(song.videoId), lyrics: value),
      AsyncData(:final value?) => _PlainLyrics(lyrics: value),
      AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(songLyricsProvider(song))),
      _ => const LoadingView(),
    };
  }
}

const _lineStyle = TextStyle(fontSize: 24, height: 1.35, fontWeight: FontWeight.w700);

class _PlainLyrics extends StatelessWidget {
  const _PlainLyrics({required this.lyrics});

  final SongLyrics lyrics;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
    children: [
      Text(lyrics.plain ?? '', style: _lineStyle.copyWith(fontSize: 20, color: YtmColors.textPrimary)),
      const SizedBox(height: 24),
      Text('Source: ${lyrics.source}', style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _SyncedLyrics extends ConsumerStatefulWidget {
  const _SyncedLyrics({super.key, required this.lyrics});

  final SongLyrics lyrics;

  @override
  ConsumerState<_SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends ConsumerState<_SyncedLyrics> {
  late final List<LyricLine> _lines = widget.lyrics.synced!;
  late final List<GlobalKey> _keys = List.generate(_lines.length, (_) => GlobalKey());
  int _active = -2;

  /// After the user scrolls by hand, stop following the song for a few seconds.
  DateTime _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);

  void _follow(int index) {
    if (index < 0 || DateTime.now().difference(_userScrolledAt) < const Duration(seconds: 4)) return;
    final ctx = _keys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, alignment: 0.35, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    // A little lead so the line lights up as it starts, like YouTube Music.
    final active = activeLineIndex(_lines, position + const Duration(milliseconds: 250));
    if (active != _active) {
      _active = active;
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow(active));
    }
    final handler = ref.read(audioHandlerProvider);

    return NotificationListener<UserScrollNotification>(
      onNotification: (n) {
        if (n.direction != ScrollDirection.idle) _userScrolledAt = DateTime.now();
        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.sizeOf(context).height * 0.4),
        itemCount: _lines.length + 1,
        itemBuilder: (context, i) {
          if (i == _lines.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text('Source: ${widget.lyrics.source}', style: Theme.of(context).textTheme.bodySmall),
            );
          }
          final line = _lines[i];
          final isActive = i == active;
          return GestureDetector(
            key: _keys[i],
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);
              unawaited(handler.seek(line.start));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: _lineStyle.copyWith(
                  color: isActive
                      ? YtmColors.textPrimary
                      : i < active
                      ? YtmColors.textPrimary.withValues(alpha: 0.55)
                      : YtmColors.textPrimary.withValues(alpha: 0.35),
                ),
                child: Text(line.text.isEmpty ? '♪' : line.text),
              ),
            ),
          );
        },
      ),
    );
  }
}
