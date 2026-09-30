import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens matched to the YouTube Music Android app (dark only).
abstract final class YtmColors {
  static const background = Color(0xFF030303);
  static const surface = Color(0xFF212121);
  static const elevated = Color(0xFF2A2A2A);
  static const navBar = Color(0xFF0F0F0F);
  static const divider = Color(0x1AFFFFFF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAA);
  static const brandRed = Color(0xFFFF0000);
  static const chip = Color(0x1AFFFFFF);
  static const chipSelected = Color(0xFFFFFFFF);
  static const progressTrack = Color(0x33FFFFFF);
}

abstract final class YtmSizes {
  static const pagePadding = 16.0;
  static const cardRadius = 4.0;
  static const pillRadius = 18.0;
  static const miniPlayerHeight = 64.0;
  static const navBarHeight = 64.0;
  static const listThumb = 48.0;
  static const carouselCard = 160.0;
}

ThemeData buildYtmTheme() {
  const scheme = ColorScheme.dark(
    primary: YtmColors.textPrimary,
    onPrimary: Colors.black,
    secondary: YtmColors.brandRed,
    surface: YtmColors.background,
    onSurface: YtmColors.textPrimary,
    surfaceContainer: YtmColors.surface,
    surfaceContainerHigh: YtmColors.elevated,
    outlineVariant: YtmColors.divider,
  );
  const base = TextTheme(
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.2),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14, color: YtmColors.textSecondary),
    bodySmall: TextStyle(fontSize: 12, color: YtmColors.textSecondary),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: YtmColors.background,
    fontFamily: 'Roboto',
    textTheme: base
        .apply(bodyColor: YtmColors.textPrimary, displayColor: YtmColors.textPrimary)
        .copyWith(bodyMedium: base.bodyMedium, bodySmall: base.bodySmall),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: YtmColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: YtmColors.navBar,
      ),
    ),
    dividerTheme: const DividerThemeData(color: YtmColors.divider, space: 1, thickness: 1),
    iconTheme: const IconThemeData(color: YtmColors.textPrimary),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: YtmColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Color(0x66FFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: YtmColors.elevated,
      contentTextStyle: TextStyle(color: YtmColors.textPrimary, fontSize: 14),
      actionTextColor: YtmColors.textPrimary,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: YtmColors.textPrimary,
      inactiveTrackColor: YtmColors.progressTrack,
      thumbColor: YtmColors.textPrimary,
      trackHeight: 2,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: YtmColors.textPrimary),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      hintStyle: TextStyle(color: YtmColors.textSecondary),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: YtmColors.brandRed),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder(backgroundColor: YtmColors.background)},
    ),
  );
}
