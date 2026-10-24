class MealWindow {
  const MealWindow({
    required this.slot,
    required this.startMinutes,
    required this.endMinutes,
  });

  final String slot;
  final int startMinutes;
  final int endMinutes;
}

List<MealWindow> suggestedMealWindows({
  required int wakeMinutes,
  required int sleepMinutes,
}) {
  final endOfDay = sleepMinutes <= wakeMinutes
      ? sleepMinutes + 1440
      : sleepMinutes;
  return <MealWindow>[
    MealWindow(
      slot: 'BREAKFAST',
      startMinutes: _wrap(wakeMinutes + 30),
      endMinutes: _wrap(wakeMinutes + 150),
    ),
    MealWindow(
      slot: 'LUNCH',
      startMinutes: _wrap(wakeMinutes + 360),
      endMinutes: _wrap(wakeMinutes + 480),
    ),
    MealWindow(
      slot: 'SNACK',
      startMinutes: _wrap(wakeMinutes + 570),
      endMinutes: _wrap(wakeMinutes + 630),
    ),
    MealWindow(
      slot: 'DINNER',
      startMinutes: _wrap(_max(wakeMinutes + 690, endOfDay - 240)),
      endMinutes: _wrap(_max(wakeMinutes + 780, endOfDay - 150)),
    ),
  ];
}

int _wrap(int minutes) {
  final wrapped = minutes % 1440;
  return wrapped < 0 ? wrapped + 1440 : wrapped;
}

int _max(int a, int b) => a > b ? a : b;
