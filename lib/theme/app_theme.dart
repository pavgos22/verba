import 'package:flutter/material.dart';

import 'app_colors.dart';

class _OutlineThumbShape extends SliderComponentShape {
  const _OutlineThumbShape({required this.fill, required this.border});

  final Color fill;
  final Color border;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(16, 16);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, 8, Paint()..color = fill);
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

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
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        enabledMouseCursor: SystemMouseCursors.click,
        disabledMouseCursor: SystemMouseCursors.basic,
      ),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 6,
      activeTrackColor: colors.primary,
      inactiveTrackColor: colors.muted,
      thumbShape: _OutlineThumbShape(fill: colors.background, border: colors.primary),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      overlayColor: colors.primary.withValues(alpha: 0.12),
      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 1.5),
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: colors.mutedForeground,
      valueIndicatorColor: colors.foreground,
      valueIndicatorTextStyle:
          TextStyle(color: colors.background, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
      mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      titleTextStyle: TextStyle(
          fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: colors.foreground),
      contentTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: colors.foreground),
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
