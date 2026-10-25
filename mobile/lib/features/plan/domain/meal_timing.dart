enum MealWhen { logged, now, missed, upcoming, untimed }

int clockMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) {
    return 0;
  }
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return hour * 60 + minute;
}

/// Logged wins. With no window the item has no time and no late/now badge.
MealWhen mealWhen({
  required bool logged,
  required String? start,
  required String? end,
  required int nowMinutes,
}) {
  if (logged) {
    return MealWhen.logged;
  }
  if (start == null || end == null || start.isEmpty || end.isEmpty) {
    return MealWhen.untimed;
  }
  final startMinutes = clockMinutes(start);
  final endMinutes = clockMinutes(end);
  if (nowMinutes < startMinutes) {
    return MealWhen.upcoming;
  }
  if (nowMinutes <= endMinutes) {
    return MealWhen.now;
  }
  return MealWhen.missed;
}

/// Share of the window that has elapsed, from 0 to 1.
double windowProgress({
  required String start,
  required String end,
  required int nowMinutes,
}) {
  final startMinutes = clockMinutes(start);
  final endMinutes = clockMinutes(end);
  final span = endMinutes - startMinutes;
  if (span <= 0) {
    return 1;
  }
  final elapsed = nowMinutes - startMinutes;
  if (elapsed <= 0) {
    return 0;
  }
  if (elapsed >= span) {
    return 1;
  }
  return elapsed / span;
}
