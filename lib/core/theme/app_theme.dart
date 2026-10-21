import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

class AppTheme {
  static ThemeData dark() => _build(TheticsPalette.dark, Brightness.dark);

  static ThemeData light() => _build(TheticsPalette.light, Brightness.light);

  static ThemeData _build(TheticsPalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.text,
      onSecondary: p.bg,
      error: p.danger,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.text,
      surfaceContainerHighest: p.cardHigh,
      onSurfaceVariant: p.muted,
      outline: p.line,
      outlineVariant: p.line,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: p.text,
      onInverseSurface: p.bg,
      inversePrimary: p.bg,
      tertiary: p.ember,
      onTertiary: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      fontFamily: 'Manrope',
      splashFactory: InkSparkle.splashFactory,
    );

    final display = <String, TextStyle>{
      'displayLarge': TextStyle(
        fontFamily: 'BarlowCondensed',
        fontWeight: FontWeight.w700,
        fontSize: 64,
        height: 0.92,
        letterSpacing: -0.5,
        color: p.text,
      ),
      'displayMedium': TextStyle(
        fontFamily: 'BarlowCondensed',
        fontWeight: FontWeight.w700,
        fontSize: 48,
        height: 0.95,
        letterSpacing: -0.2,
        color: p.text,
      ),
      'displaySmall': TextStyle(
        fontFamily: 'BarlowCondensed',
        fontWeight: FontWeight.w600,
        fontSize: 38,
        height: 1,
        color: p.text,
      ),
      'headlineLarge': TextStyle(
        fontFamily: 'BarlowCondensed',
        fontWeight: FontWeight.w700,
        fontSize: 34,
        height: 1,
        letterSpacing: 0,
        color: p.text,
      ),
      'headlineMedium': TextStyle(
        fontFamily: 'BarlowCondensed',
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 1.05,
        color: p.text,
      ),
      'headlineSmall': TextStyle(
        fontFamily: 'BarlowCondensed',
        fontWeight: FontWeight.w600,
        fontSize: 23,
        height: 1.1,
        color: p.text,
      ),
      'titleLarge': TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 19,
        height: 1.25,
        letterSpacing: -0.25,
        color: p.text,
      ),
      'titleMedium': TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15.5,
        height: 1.3,
        color: p.text,
      ),
      'titleSmall': TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        height: 1.3,
        letterSpacing: 0.1,
        color: p.text,
      ),
      'bodyLarge': TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 1.45,
        color: p.text,
      ),
      'bodyMedium': TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1.45,
        color: p.text,
      ),
      'bodySmall': TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 1.4,
        color: p.muted,
      ),
      'labelLarge': TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: 0.4,
        color: p.text,
      ),
      'labelMedium': TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11.5,
        letterSpacing: 0.25,
        color: p.muted,
      ),
      'labelSmall': TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: 1.1,
        color: p.muted,
      ),
    };

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: display['displayLarge'],
        displayMedium: display['displayMedium'],
        displaySmall: display['displaySmall'],
        headlineLarge: display['headlineLarge'],
        headlineMedium: display['headlineMedium'],
        headlineSmall: display['headlineSmall'],
        titleLarge: display['titleLarge'],
        titleMedium: display['titleMedium'],
        titleSmall: display['titleSmall'],
        bodyLarge: display['bodyLarge'],
        bodyMedium: display['bodyMedium'],
        bodySmall: display['bodySmall'],
        labelLarge: display['labelLarge'],
        labelMedium: display['labelMedium'],
        labelSmall: display['labelSmall'],
      ),
      extensions: <ThemeExtension<dynamic>>[p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: display['headlineSmall'],
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.isDark ? const Color(0xFF0C0E10) : p.surface,
        indicatorColor: p.accent.withValues(alpha: p.isDark ? 0.16 : 0.35),
        height: 70,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.2,
            color: selected ? p.text : p.faint,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(size: 23, color: selected ? p.accent : p.faint);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.isDark ? p.cardHigh.withValues(alpha: 0.7) : p.cardHigh,
        hintStyle: TextStyle(
          color: p.faint,
          fontWeight: FontWeight.w500,
          fontSize: 14.5,
        ),
        labelStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
        floatingLabelStyle: TextStyle(color: p.accent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.danger),
        ),
        errorStyle: TextStyle(color: p.danger, fontSize: 11.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          minimumSize: const Size(64, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size(64, 52),
          side: BorderSide(color: p.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.text,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.cardHigh,
        selectedColor: p.accent,
        disabledColor: p.cardHigh,
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: TextStyle(
          color: p.text,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        secondaryLabelStyle: TextStyle(
          color: p.onAccent,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        checkmarkColor: p.onAccent,
        showCheckmark: false,
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.isDark ? p.text : p.text,
        contentTextStyle: TextStyle(
          color: p.isDark ? p.bg : p.surface,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.all(16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        modalBarrierColor: Colors.black.withValues(alpha: 0.72),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: p.line,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.line,
        circularTrackColor: p.line,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.onAccent : p.faint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.accent : p.line,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.text,
        unselectedLabelColor: p.faint,
        indicatorColor: p.accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        weekdayStyle: TextStyle(color: p.muted),
        dayStyle: TextStyle(color: p.text),
        headerBackgroundColor: p.card,
        headerForegroundColor: p.text,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.accent,
        inactiveTrackColor: p.line,
        thumbColor: p.accent,
        overlayColor: p.accent.withValues(alpha: 0.14),
        valueIndicatorColor: p.accent,
        valueIndicatorTextStyle: TextStyle(
          color: p.onAccent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
