import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatCount(BuildContext context, num value, {int fractionDigits = 0}) {
  return NumberFormat.decimalPatternDigits(
    locale: Localizations.localeOf(context).toString(),
    decimalDigits: fractionDigits,
  ).format(value);
}

String formatMeasure(BuildContext context, num value) {
  final whole = value == value.roundToDouble();
  return formatCount(context, value, fractionDigits: whole ? 0 : 1);
}

String localeNameOf(BuildContext context) {
  return Localizations.localeOf(context).toString();
}
