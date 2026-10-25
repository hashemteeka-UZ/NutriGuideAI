/// Calendar date of [value] as YYYY-MM-DD, without shifting time zones.
///
/// A server date parsed as UTC midnight keeps that calendar day.
String isoDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// The device's local calendar day for [value].
DateTime dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime dateFromIso(String iso) {
  final parts = iso.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Inclusive range stored on the phone: yesterday through today + 13 days.
({DateTime from, DateTime to}) planCacheRange(DateTime now) {
  final today = dateOnly(now);
  return (
    from: today.subtract(const Duration(days: 1)),
    to: today.add(const Duration(days: 13)),
  );
}

/// The week the generator and the plan tab show: today through today + 6.
List<DateTime> weekDates(DateTime now) {
  final today = dateOnly(now);
  return <DateTime>[
    for (var offset = 0; offset < 7; offset++)
      today.add(Duration(days: offset)),
  ];
}

String shoppingRangeKey(DateTime from, DateTime to) {
  return '${isoDate(from)}_${isoDate(to)}';
}
