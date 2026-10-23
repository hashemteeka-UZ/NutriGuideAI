import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.fg,
    required this.fg2,
    required this.fg3,
    required this.brand,
    required this.brand2,
    required this.brandSoft,
    required this.onBrand,
    required this.signal,
    required this.signalSoft,
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
    required this.fiber,
    required this.water,
    required this.ok,
    required this.part,
    required this.miss,
    required this.warn,
    required this.danger,
    required this.heroStart,
    required this.heroMid,
    required this.heroEnd,
    required this.numeric,
  });

  final Color bg;
  final Color bg2;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color line;
  final Color fg;
  final Color fg2;
  final Color fg3;
  final Color brand;
  final Color brand2;
  final Color brandSoft;
  final Color onBrand;
  final Color signal;
  final Color signalSoft;
  final Color kcal;
  final Color protein;
  final Color carb;
  final Color fat;
  final Color fiber;
  final Color water;
  final Color ok;
  final Color part;
  final Color miss;
  final Color warn;
  final Color danger;
  final Color heroStart;
  final Color heroMid;
  final Color heroEnd;
  final TextStyle numeric;

  static const light = AppColors(
    bg: Color(0xFFF3F7F5),
    bg2: Color(0xFFE8F1ED),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF2F6F4),
    surface3: Color(0xFFE7EEEB),
    line: Color(0xFFDDE7E3),
    fg: Color(0xFF0F1D1A),
    fg2: Color(0xFF4A5D58),
    fg3: Color(0xFF7E8F8B),
    brand: Color(0xFF0FA473),
    brand2: Color(0xFF0B8A61),
    brandSoft: Color(0xFFD7F3E8),
    onBrand: Color(0xFFFFFFFF),
    signal: Color(0xFF0EA5E9),
    signalSoft: Color(0xFFDCF2FC),
    kcal: Color(0xFFF2781F),
    protein: Color(0xFFE5536A),
    carb: Color(0xFF3D7FE6),
    fat: Color(0xFFE3A21A),
    fiber: Color(0xFF22A866),
    water: Color(0xFF1A9BE0),
    ok: Color(0xFF16A36B),
    part: Color(0xFFD99511),
    miss: Color(0xFF8A97A3),
    warn: Color(0xFFE26A2C),
    danger: Color(0xFFD9434F),
    heroStart: Color(0xFF0FA473),
    heroMid: Color(0xFF12B39A),
    heroEnd: Color(0xFF1AA7E0),
    numeric: _numeric,
  );

  static const dark = AppColors(
    bg: Color(0xFF0A111C),
    bg2: Color(0xFF0E1726),
    surface: Color(0xFF131D2D),
    surface2: Color(0xFF192538),
    surface3: Color(0xFF203046),
    line: Color(0xFF24334A),
    fg: Color(0xFFEEF3F8),
    fg2: Color(0xFFA7B4C6),
    fg3: Color(0xFF6F7E94),
    brand: Color(0xFF2BD49A),
    brand2: Color(0xFF5BE3B4),
    brandSoft: Color(0xFF123B33),
    onBrand: Color(0xFF04241A),
    signal: Color(0xFF38BDF8),
    signalSoft: Color(0xFF0F3148),
    kcal: Color(0xFFFF9147),
    protein: Color(0xFFFF6B81),
    carb: Color(0xFF5C9BFF),
    fat: Color(0xFFFFC23D),
    fiber: Color(0xFF3DD68C),
    water: Color(0xFF3FB7F5),
    ok: Color(0xFF34D399),
    part: Color(0xFFFBBF24),
    miss: Color(0xFF7C8BA0),
    warn: Color(0xFFFB923C),
    danger: Color(0xFFF87171),
    heroStart: Color(0xFF0E8F68),
    heroMid: Color(0xFF0F8C86),
    heroEnd: Color(0xFF1478B8),
    numeric: _numeric,
  );

  static const _numeric = TextStyle(
    fontFamily: 'Readex Pro',
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[heroStart, heroMid, heroEnd],
    stops: const <double>[0, 0.45, 1],
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? bg2,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? line,
    Color? fg,
    Color? fg2,
    Color? fg3,
    Color? brand,
    Color? brand2,
    Color? brandSoft,
    Color? onBrand,
    Color? signal,
    Color? signalSoft,
    Color? kcal,
    Color? protein,
    Color? carb,
    Color? fat,
    Color? fiber,
    Color? water,
    Color? ok,
    Color? part,
    Color? miss,
    Color? warn,
    Color? danger,
    Color? heroStart,
    Color? heroMid,
    Color? heroEnd,
    TextStyle? numeric,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      bg2: bg2 ?? this.bg2,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      line: line ?? this.line,
      fg: fg ?? this.fg,
      fg2: fg2 ?? this.fg2,
      fg3: fg3 ?? this.fg3,
      brand: brand ?? this.brand,
      brand2: brand2 ?? this.brand2,
      brandSoft: brandSoft ?? this.brandSoft,
      onBrand: onBrand ?? this.onBrand,
      signal: signal ?? this.signal,
      signalSoft: signalSoft ?? this.signalSoft,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      carb: carb ?? this.carb,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      water: water ?? this.water,
      ok: ok ?? this.ok,
      part: part ?? this.part,
      miss: miss ?? this.miss,
      warn: warn ?? this.warn,
      danger: danger ?? this.danger,
      heroStart: heroStart ?? this.heroStart,
      heroMid: heroMid ?? this.heroMid,
      heroEnd: heroEnd ?? this.heroEnd,
      numeric: numeric ?? this.numeric,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      line: Color.lerp(line, other.line, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      fg2: Color.lerp(fg2, other.fg2, t)!,
      fg3: Color.lerp(fg3, other.fg3, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brand2: Color.lerp(brand2, other.brand2, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      signal: Color.lerp(signal, other.signal, t)!,
      signalSoft: Color.lerp(signalSoft, other.signalSoft, t)!,
      kcal: Color.lerp(kcal, other.kcal, t)!,
      protein: Color.lerp(protein, other.protein, t)!,
      carb: Color.lerp(carb, other.carb, t)!,
      fat: Color.lerp(fat, other.fat, t)!,
      fiber: Color.lerp(fiber, other.fiber, t)!,
      water: Color.lerp(water, other.water, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      part: Color.lerp(part, other.part, t)!,
      miss: Color.lerp(miss, other.miss, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroMid: Color.lerp(heroMid, other.heroMid, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      numeric: TextStyle.lerp(numeric, other.numeric, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
