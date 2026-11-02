import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatAmount(BuildContext context, num value) {
  final whole = value == value.roundToDouble();
  return NumberFormat.decimalPatternDigits(
    locale: Localizations.localeOf(context).toString(),
    decimalDigits: whole ? 0 : 1,
  ).format(value);
}

String formatUpdated(BuildContext context, DateTime value) {
  final locale = Localizations.localeOf(context).toString();
  // Western digits, as everywhere else in the app (P2z).
  return (DateFormat.yMMMd(
    locale,
  ).add_jm()..useNativeDigits = false).format(value.toLocal());
}
