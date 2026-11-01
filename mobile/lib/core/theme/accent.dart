import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// The app accent (V5, approved in prototype v3): it follows the goal by
/// default and can be chosen in «المظهر». Only the brand colours change;
/// energy, macro and water colours never do.
enum AccentChoice { auto, emerald, teal, plum }

/// Stored on the device, like the theme mode.
const accentPreferenceKey = 'ng.accent';

/// One accent in light and dark (prototype `ACC`). White text on every
/// light brand colour has a contrast of 4.5:1 or more.
class AccentPalette {
  const AccentPalette({
    required this.light,
    required this.dark,
    required this.heroLight,
    required this.heroDark,
  });

  /// brand, brand2, onBrand.
  final (Color, Color, Color) light;
  final (Color, Color, Color) dark;

  /// Hero gradient start, middle, end.
  final (Color, Color, Color) heroLight;
  final (Color, Color, Color) heroDark;

  static const emerald = AccentPalette(
    light: (Color(0xFF08875D), Color(0xFF065F46), Color(0xFFFFFFFF)),
    dark: (Color(0xFF34D399), Color(0xFFA7F3D0), Color(0xFF04241A)),
    heroLight: (Color(0xFF08875D), Color(0xFF0E9F8A), Color(0xFF1A8FC9)),
    heroDark: (Color(0xFF0E8F68), Color(0xFF0F8C86), Color(0xFF1478B8)),
  );

  static const teal = AccentPalette(
    light: (Color(0xFF0E7C74), Color(0xFF115E59), Color(0xFFFFFFFF)),
    dark: (Color(0xFF2DD4BF), Color(0xFF99F6E4), Color(0xFF042F2E)),
    heroLight: (Color(0xFF0E7C74), Color(0xFF0F8C9A), Color(0xFF2C7BD8)),
    heroDark: (Color(0xFF0F766E), Color(0xFF0E7490), Color(0xFF1D5FC4)),
  );

  static const plum = AccentPalette(
    light: (Color(0xFFA21CAF), Color(0xFF86198F), Color(0xFFFFFFFF)),
    dark: (Color(0xFFE879F9), Color(0xFFF5D0FE), Color(0xFF3B0A3F)),
    heroLight: (Color(0xFF86198F), Color(0xFFA21CAF), Color(0xFFDB2777)),
    heroDark: (Color(0xFF701A75), Color(0xFF86198F), Color(0xFFBE185D)),
  );

  /// The tokens with this accent; [dark] picks the dark variant.
  AppColors apply(AppColors base, {required bool dark}) {
    final (brand, brand2, onBrand) = dark ? this.dark : light;
    final (start, mid, end) = dark ? heroDark : heroLight;
    return base.copyWith(
      brand: brand,
      brand2: brand2,
      onBrand: onBrand,
      brandSoft: Color.lerp(base.surface, brand, dark ? 0.24 : 0.14),
      heroStart: start,
      heroMid: mid,
      heroEnd: end,
    );
  }
}

/// LOSE green, MAINTAIN teal, GAIN plum.
AccentPalette accentForGoal(String? goal) {
  return switch (goal) {
    'MAINTAIN' => AccentPalette.teal,
    'GAIN' => AccentPalette.plum,
    _ => AccentPalette.emerald,
  };
}

AccentPalette? accentFor(AccentChoice choice, {String? goal}) {
  return switch (choice) {
    AccentChoice.emerald => AccentPalette.emerald,
    AccentChoice.teal => AccentPalette.teal,
    AccentChoice.plum => AccentPalette.plum,
    AccentChoice.auto => goal == null ? null : accentForGoal(goal),
  };
}

AccentChoice accentChoiceFromName(String? name) {
  for (final choice in AccentChoice.values) {
    if (choice.name == name) {
      return choice;
    }
  }
  return AccentChoice.auto;
}

final accentChoiceProvider =
    NotifierProvider<AccentChoiceController, AccentChoice>(
      AccentChoiceController.new,
    );

class AccentChoiceController extends Notifier<AccentChoice> {
  @override
  AccentChoice build() {
    unawaited(_load());
    return AccentChoice.auto;
  }

  Future<void> select(AccentChoice choice) async {
    state = choice;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(accentPreferenceKey, choice.name);
    } on Object {
      // The choice still applies until the process ends.
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(accentPreferenceKey);
      if (!ref.mounted || stored == null) {
        return;
      }
      state = accentChoiceFromName(stored);
    } on Object {
      // Follow the goal when preferences cannot be read.
    }
  }
}
