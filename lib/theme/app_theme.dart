import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildTheme(Brightness brightness) {
  final colors = brightness == Brightness.light ? VerbaColors.light : VerbaColors.dark;
  final light = brightness == Brightness.light;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: colors.background,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    hoverColor: light ? const Color(0x14000000) : const Color(0x1FFFFFFF),
    highlightColor: light ? const Color(0x1F000000) : const Color(0x29FFFFFF),
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.primaryForeground,
      secondary: colors.muted,
      onSecondary: colors.foreground,
      error: colors.destructive,
      onError: Colors.white,
      surface: colors.background,
      onSurface: colors.foreground,
      outline: colors.border,
    ),
  );
  return base.copyWith(
    extensions: [colors],
    dividerTheme: DividerThemeData(color: colors.border, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.primaryForeground,
        overlayColor: colors.primaryForeground,
        enabledMouseCursor: SystemMouseCursors.click,
        disabledMouseCursor: SystemMouseCursors.basic,
        splashFactory: NoSplash.splashFactory,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.foreground,
        overlayColor: colors.foreground,
        enabledMouseCursor: SystemMouseCursors.click,
        disabledMouseCursor: SystemMouseCursors.basic,
        splashFactory: NoSplash.splashFactory,
        side: BorderSide(color: colors.border),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.mutedForeground,
        overlayColor: colors.foreground,
        enabledMouseCursor: SystemMouseCursors.click,
        disabledMouseCursor: SystemMouseCursors.basic,
        splashFactory: NoSplash.splashFactory,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
        enabledMouseCursor: SystemMouseCursors.click,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colors.foreground,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, color: colors.background),
    ),
  );
}
