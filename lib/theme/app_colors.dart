import 'package:flutter/material.dart';

class VerbaColors extends ThemeExtension<VerbaColors> {
  const VerbaColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.inputBorder,
    required this.primary,
    required this.primaryForeground,
    required this.accent,
    required this.sidebar,
    required this.destructive,
    required this.success,
    required this.warning,
    required this.ring,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color inputBorder;
  final Color primary;
  final Color primaryForeground;
  final Color accent;
  final Color sidebar;
  final Color destructive;
  final Color success;
  final Color warning;
  final Color ring;

  static const light = VerbaColors(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF0A0A0A),
    card: Color(0xFFFFFFFF),
    muted: Color(0xFFF5F5F5),
    mutedForeground: Color(0xFF737373),
    border: Color(0xFFE5E5E5),
    inputBorder: Color(0xFFE5E5E5),
    primary: Color(0xFF171717),
    primaryForeground: Color(0xFFFAFAFA),
    accent: Color(0xFFF5F5F5),
    sidebar: Color(0xFFFAFAFA),
    destructive: Color(0xFFDC2626),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    ring: Color(0xFFA3A3A3),
  );

  static const dark = VerbaColors(
    background: Color(0xFF0A0A0A),
    foreground: Color(0xFFFAFAFA),
    card: Color(0xFF171717),
    muted: Color(0xFF262626),
    mutedForeground: Color(0xFFA3A3A3),
    border: Color(0xFF262626),
    inputBorder: Color(0xFF333333),
    primary: Color(0xFFFAFAFA),
    primaryForeground: Color(0xFF171717),
    accent: Color(0xFF262626),
    sidebar: Color(0xFF111111),
    destructive: Color(0xFFEF4444),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    ring: Color(0xFF525252),
  );

  @override
  VerbaColors copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? muted,
    Color? mutedForeground,
    Color? border,
    Color? inputBorder,
    Color? primary,
    Color? primaryForeground,
    Color? accent,
    Color? sidebar,
    Color? destructive,
    Color? success,
    Color? warning,
    Color? ring,
  }) {
    return VerbaColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      inputBorder: inputBorder ?? this.inputBorder,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      accent: accent ?? this.accent,
      sidebar: sidebar ?? this.sidebar,
      destructive: destructive ?? this.destructive,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      ring: ring ?? this.ring,
    );
  }

  @override
  VerbaColors lerp(ThemeExtension<VerbaColors>? other, double t) {
    if (other is! VerbaColors) return this;
    return VerbaColors(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      card: Color.lerp(card, other.card, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(primaryForeground, other.primaryForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
    );
  }
}

extension VerbaColorsContext on BuildContext {
  VerbaColors get c => Theme.of(this).extension<VerbaColors>()!;
}
