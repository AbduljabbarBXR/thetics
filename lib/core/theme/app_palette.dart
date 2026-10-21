import 'package:flutter/material.dart';

@immutable
class TheticsPalette extends ThemeExtension<TheticsPalette> {
  const TheticsPalette({
    required this.bg,
    required this.surface,
    required this.card,
    required this.cardHigh,
    required this.line,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.onAccent,
    required this.ember,
    required this.sky,
    required this.lilac,
    required this.success,
    required this.danger,
    required this.isDark,
  });

  final Color bg;
  final Color surface;
  final Color card;
  final Color cardHigh;
  final Color line;
  final Color text;
  final Color muted;
  final Color faint;
  final Color accent;
  final Color onAccent;
  final Color ember;
  final Color sky;
  final Color lilac;
  final Color success;
  final Color danger;
  final bool isDark;

  static const dark = TheticsPalette(
    bg: Color(0xFF08090A),
    surface: Color(0xFF101215),
    card: Color(0xFF15181B),
    cardHigh: Color(0xFF1B1F23),
    line: Color(0xFF262B30),
    text: Color(0xFFF3F4EC),
    muted: Color(0xFF9BA1A6),
    faint: Color(0xFF686E74),
    accent: Color(0xFFD7FF3E),
    onAccent: Color(0xFF0A0B08),
    ember: Color(0xFFFF6A3D),
    sky: Color(0xFF6FD3FF),
    lilac: Color(0xFFB99CFF),
    success: Color(0xFF7CE38B),
    danger: Color(0xFFFF5D5D),
    isDark: true,
  );

  static const light = TheticsPalette(
    bg: Color(0xFFF3F4EC),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardHigh: Color(0xFFF7F8F1),
    line: Color(0xFFE1E3D8),
    text: Color(0xFF101210),
    muted: Color(0xFF626865),
    faint: Color(0xFF8E948F),
    accent: Color(0xFFB9E21C),
    onAccent: Color(0xFF101210),
    ember: Color(0xFFE5522A),
    sky: Color(0xFF1D87B8),
    lilac: Color(0xFF7655C9),
    success: Color(0xFF1E7D36),
    danger: Color(0xFFC73838),
    isDark: false,
  );

  @override
  TheticsPalette copyWith({
    Color? bg,
    Color? surface,
    Color? card,
    Color? cardHigh,
    Color? line,
    Color? text,
    Color? muted,
    Color? faint,
    Color? accent,
    Color? onAccent,
    Color? ember,
    Color? sky,
    Color? lilac,
    Color? success,
    Color? danger,
    bool? isDark,
  }) {
    return TheticsPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      cardHigh: cardHigh ?? this.cardHigh,
      line: line ?? this.line,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      ember: ember ?? this.ember,
      sky: sky ?? this.sky,
      lilac: lilac ?? this.lilac,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  TheticsPalette lerp(ThemeExtension<TheticsPalette>? other, double t) {
    if (other is! TheticsPalette) return this;
    return TheticsPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardHigh: Color.lerp(cardHigh, other.cardHigh, t)!,
      line: Color.lerp(line, other.line, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      ember: Color.lerp(ember, other.ember, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      lilac: Color.lerp(lilac, other.lilac, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension TheticsPaletteX on BuildContext {
  TheticsPalette get palette =>
      Theme.of(this).extension<TheticsPalette>() ?? TheticsPalette.dark;
}
