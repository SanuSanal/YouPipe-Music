import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../navigation.dart';
import '../theme/ytm_theme.dart';

/// Cylinder badge + "YouPipe Music" wordmark (top-left of the app bar).
class YouPipeWordmark extends StatelessWidget {
  const YouPipeWordmark({super.key, this.height = 26});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/branding/logo.svg', height: height, width: height),
        const SizedBox(width: 6),
        Text(
          'YouPipe Music',
          style: TextStyle(
            fontSize: height * 0.78,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: YtmColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Search + settings buttons shown on the top bar of every tab.
class TopBarActions extends ConsumerWidget {
  const TopBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Icons.search), tooltip: 'Search', onPressed: () => openSearch(context, ref)),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => openSettings(context, ref),
          icon: const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFF5E35B1),
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
