import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const String fontFamily = 'IBM Plex Sans Arabic';

  static ThemeData light() => _theme(Brightness.light, AppColors.light);

  static ThemeData dark() => _theme(Brightness.dark, AppColors.dark);

  static ThemeData _theme(Brightness brightness, AppColors colors) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.brand,
          brightness: brightness,
        ).copyWith(
          primary: colors.brand,
          onPrimary: colors.onBrand,
          primaryContainer: colors.brandSoft,
          secondary: colors.signal,
          onSecondary: colors.fg,
          secondaryContainer: colors.signalSoft,
          error: colors.danger,
          onError: brightness == Brightness.light
              ? const Color(0xFFFFFFFF)
              : colors.bg,
          surface: colors.surface,
          onSurface: colors.fg,
          outline: colors.line,
        );
    final typography = brightness == Brightness.light
        ? Typography.material2021().black
        : Typography.material2021().white;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.bg,
      fontFamily: fontFamily,
      extensions: <ThemeExtension<dynamic>>[colors],
      textTheme: typography.apply(
        bodyColor: colors.fg,
        displayColor: colors.fg,
        fontFamily: fontFamily,
      ),
    );
  }
}
