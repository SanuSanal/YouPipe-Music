import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../innertube/models.dart';
import '../theme/ytm_theme.dart';
import 'thumbnail.dart';

/// Picks a dark tint from artwork for the page background gradient (YouTube Music style).
class ArtworkTint extends StatefulWidget {
  const ArtworkTint({super.key, required this.url, required this.builder});

  final String? url;
  final Widget Function(BuildContext context, Color tint) builder;

  @override
  State<ArtworkTint> createState() => _ArtworkTintState();
}

class _ArtworkTintState extends State<ArtworkTint> {
  static final _cache = <String, Color>{};
  Color _tint = YtmColors.surface;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ArtworkTint old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _load();
  }

  Future<void> _load() async {
    final url = widget.url;
    if (url == null) return;
    final cached = _cache[url];
    if (cached != null) {
      setState(() => _tint = cached);
      return;
    }
    try {
      final scheme = await ColorScheme.fromImageProvider(
        provider: CachedNetworkImageProvider(url),
        brightness: Brightness.dark,
      );
      final hsl = HSLColor.fromColor(scheme.primaryContainer);
      final tint = hsl.withLightness(hsl.lightness.clamp(0.18, 0.28)).toColor();
      _cache[url] = tint;
      if (mounted && widget.url == url) setState(() => _tint = tint);
    } catch (_) {
      // Keep the neutral tint.
    }
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
    tween: ColorTween(end: _tint),
    duration: const Duration(milliseconds: 400),
    builder: (context, c, _) => widget.builder(context, c ?? _tint),
  );
}

/// Album / playlist header: artwork, title, owner line, meta, action row, description.
class CollectionHeader extends StatelessWidget {
  const CollectionHeader({
    super.key,
    required this.thumbnails,
    required this.title,
    required this.onPlay,
    this.ownerName,
    this.ownerThumbnails = const [],
    this.onOwnerTap,
    this.meta,
    this.secondMeta,
    this.description,
    this.saved = false,
    this.onSave,
    this.onShuffle,
    this.onDownload,
    this.downloaded = false,
    this.onShare,
    this.onMore,
  });

  final List<Thumbnail> thumbnails;
  final String title;
  final String? ownerName;
  final List<Thumbnail> ownerThumbnails;
  final VoidCallback? onOwnerTap;
  final String? meta;
  final String? secondMeta;
  final String? description;
  final bool saved;
  final VoidCallback onPlay;
  final VoidCallback? onSave;
  final VoidCallback? onShuffle;
  final VoidCallback? onDownload;

  /// All songs are available offline.
  final bool downloaded;
  final VoidCallback? onShare;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artSize = (MediaQuery.sizeOf(context).width * 0.62).clamp(160.0, 320.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: YtmSizes.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 8))],
            ),
            child: YtImage(thumbnails: thumbnails, size: artSize, radius: 8, fallbackIcon: Icons.album),
          ),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall, maxLines: 3),
          if (ownerName != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onOwnerTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ownerThumbnails.isNotEmpty) ...[
                      YtImage(thumbnails: ownerThumbnails, size: 24, circle: true),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(ownerName!, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (meta != null) ...[
            const SizedBox(height: 6),
            Text(meta!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundAction(icon: downloaded ? Icons.download_done : Icons.download_outlined, onPressed: onDownload),
              _RoundAction(icon: saved ? Icons.library_add_check : Icons.library_add_outlined, onPressed: onSave),
              SizedBox(
                width: 64,
                height: 64,
                child: FilledButton(
                  onPressed: onPlay,
                  style: FilledButton.styleFrom(
                    backgroundColor: YtmColors.textPrimary,
                    foregroundColor: Colors.black,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.play_arrow, size: 36),
                ),
              ),
              _RoundAction(icon: Icons.share_outlined, onPressed: onShare),
              _RoundAction(icon: Icons.more_vert, onPressed: onMore),
            ],
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpandableText(description!),
          ],
          if (secondMeta != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(secondMeta!, style: theme.textTheme.bodyMedium),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filled(
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: const Color(0x1AFFFFFF),
      foregroundColor: YtmColors.textPrimary,
      disabledBackgroundColor: const Color(0x0DFFFFFF),
      fixedSize: const Size(44, 44),
    ),
    icon: Icon(icon, size: 22),
  );
}

class ExpandableText extends StatefulWidget {
  const ExpandableText(this.text, {super.key, this.maxLines = 3});

  final String text;
  final int maxLines;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            maxLines: _expanded ? null : widget.maxLines,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(_expanded ? 'Less' : 'More', style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

/// Page scaffold with a tinted gradient behind the header, fading into the background.
/// The top bar turns solid and shows [title] once the header scrolls under it.
class TintedPage extends StatefulWidget {
  const TintedPage({
    super.key,
    required this.artworkUrl,
    required this.slivers,
    this.title,
    this.titleRevealOffset = 320,
  });

  final String? artworkUrl;
  final List<Widget> slivers;
  final String? title;
  final double titleRevealOffset;

  @override
  State<TintedPage> createState() => _TintedPageState();
}

class _TintedPageState extends State<TintedPage> {
  final _scroll = ScrollController();

  double get _offset => _scroll.hasClients ? _scroll.offset : 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArtworkTint(
      url: widget.artworkUrl,
      builder: (context, tint) => Scaffold(
        body: Stack(
          children: [
            // The gradient scrolls away with the header.
            ListenableBuilder(
              listenable: _scroll,
              builder: (context, _) => Transform.translate(
                offset: Offset(0, -_offset),
                child: Container(
                  height: 520,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [tint, YtmColors.background],
                    ),
                  ),
                ),
              ),
            ),
            CustomScrollView(
              controller: _scroll,
              slivers: [
                ListenableBuilder(
                  listenable: _scroll,
                  builder: (context, _) {
                    // Solid bar with the title once the header has scrolled under it.
                    final solid = (_offset / 120).clamp(0.0, 1.0);
                    final showTitle = _offset > widget.titleRevealOffset;
                    return SliverAppBar(
                      pinned: true,
                      backgroundColor: Color.lerp(Colors.transparent, Color.lerp(tint, Colors.black, 0.35), solid),
                      title: AnimatedOpacity(
                        opacity: showTitle ? 1 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: Text(widget.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    );
                  },
                ),
                ...widget.slivers,
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
