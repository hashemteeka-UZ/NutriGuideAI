import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';

String formatWhole(BuildContext context, num value) {
  return NumberFormat.decimalPatternDigits(
    locale: Localizations.localeOf(context).toString(),
    decimalDigits: 0,
  ).format(value);
}

String formatFixed(BuildContext context, num value, int digits) {
  return NumberFormat.decimalPatternDigits(
    locale: Localizations.localeOf(context).toString(),
    decimalDigits: digits,
  ).format(value);
}

String formatHm(BuildContext context, String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) {
    return hhmm;
  }
  final locale = Localizations.localeOf(context).toString();
  final pattern = NumberFormat('00', locale);
  final hour = pattern.format(int.tryParse(parts[0]) ?? 0);
  final minute = pattern.format(int.tryParse(parts[1]) ?? 0);
  return '$hour:$minute';
}

String formatDayHeading(BuildContext context, DateTime date) {
  // Weekday, day and month («السبت 24 أكتوبر»), with the same digits as the
  // numbers around it.
  return (DateFormat(
    'EEEE d MMMM',
    Localizations.localeOf(context).toString(),
  )..useNativeDigits = false).format(date);
}

String formatWeekday(BuildContext context, DateTime date) {
  return DateFormat.EEEE(Localizations.localeOf(context).toString())
      .format(date);
}

String formatShortDay(BuildContext context, DateTime date) {
  return DateFormat.E(Localizations.localeOf(context).toString()).format(date);
}

String formatMonthDay(BuildContext context, DateTime date) {
  return (DateFormat.MMMd(
    Localizations.localeOf(context).toString(),
  )..useNativeDigits = false).format(date);
}

String slotLabel(AppLocalizations l10n, String slot) {
  return switch (slot) {
    'BREAKFAST' => l10n.mealSlotBreakfast,
    'LUNCH' => l10n.mealSlotLunch,
    'SNACK' => l10n.mealSlotSnack,
    'DINNER' => l10n.mealSlotDinner,
    _ => slot,
  };
}

String nutrientName(AppLocalizations l10n, String code) {
  return switch (code) {
    'protein' => l10n.nutrientProtein,
    'carbohydrate' || 'carb' || 'carbs' => l10n.nutrientCarbs,
    'fat' || 'total_fat' => l10n.nutrientFat,
    'fiber' => l10n.nutrientFiber,
    'sodium' => l10n.nutrientSodium,
    'sugars' => l10n.nutrientSugars,
    'saturated_fat' => l10n.nutrientSaturatedFat,
    _ => code,
  };
}

String formatDelta(BuildContext context, num delta) {
  final rounded = delta.round();
  final text = formatWhole(context, rounded.abs());
  if (rounded > 0) {
    return '+$text';
  }
  if (rounded < 0) {
    return '−$text';
  }
  return text;
}
