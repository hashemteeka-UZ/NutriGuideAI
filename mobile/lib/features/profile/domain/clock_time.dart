String formatClock(int minutes) {
  final wrapped = minutes % 1440;
  final normalized = wrapped < 0 ? wrapped + 1440 : wrapped;
  final hour = normalized ~/ 60;
  final minute = normalized % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

int daysInMonth(int year, int month) {
  final next = month == 12
      ? DateTime.utc(year + 1, 1, 1)
      : DateTime.utc(year, month + 1, 1);
  return next.subtract(const Duration(days: 1)).day;
}
