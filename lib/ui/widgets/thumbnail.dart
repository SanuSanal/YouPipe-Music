import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../innertube/models.dart';
import '../theme/ytm_theme.dart';

/// Artwork with YouTube Music's placeholder look. Circle for artists, rounded square otherwise.
class YtImage extends StatelessWidget {
  const YtImage({
    super.key,
    required this.thumbnails,
    required this.size,
    this.circle = false,
    this.radius = YtmSizes.cardRadius,
    this.aspectRatio = 1,
    this.fallbackIcon = Icons.music_note,
  });

  YtImage.url(
    String? url, {
    super.key,
    required this.size,
    this.circle = false,
    this.radius = YtmSizes.cardRadius,
    this.aspectRatio = 1,
    this.fallbackIcon = Icons.music_note,
  }) : thumbnails = [if (url != null) Thumbnail(url: url, width: 544, height: 544)];

  final List<Thumbnail> thumbnails;

  /// Width in logical pixels; height follows [aspectRatio].
  final double size;
  final bool circle;
  final double radius;
  final double aspectRatio;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final url = thumbnails.best(px.clamp(60, 1200));
    final placeholder = Container(
      color: YtmColors.surface,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: YtmColors.textSecondary, size: size * 0.4),
    );
    // Decode at the box's height in pixels, not the file's: fixed-size video thumbnails and saved
    // artwork are otherwise decoded at full resolution even in small rows (docs/performance.md).
    // Only the height is given, so the width follows the image's aspect and cover stays sharp.
    final decodeHeight = (px / aspectRatio).round();
    final image = url == null
        ? placeholder
        : url.startsWith('/')
        ? Image.file(File(url), fit: BoxFit.cover, cacheHeight: decodeHeight, errorBuilder: (_, _, _) => placeholder)
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            memCacheHeight: decodeHeight,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, _) => Container(color: YtmColors.surface),
            errorWidget: (_, _, _) => placeholder,
          );
    return SizedBox(
      width: size,
      height: size / aspectRatio,
      child: circle ? ClipOval(child: image) : ClipRRect(borderRadius: BorderRadius.circular(radius), child: image),
    );
  }
}
