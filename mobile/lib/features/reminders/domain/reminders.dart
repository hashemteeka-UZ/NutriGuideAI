/// Local reminders (#313). All off by default; inexact, repeating.
enum ReminderKind { meals, water, weighIn }

class ReminderSettings {
  const ReminderSettings({
    this.meals = false,
    this.water = false,
    this.weighIn = false,
  });

  final bool meals;
  final bool water;
  final bool weighIn;

  bool isOn(ReminderKind kind) => switch (kind) {
    ReminderKind.meals => meals,
    ReminderKind.water => water,
    ReminderKind.weighIn => weighIn,
  };

  bool get any => meals || water || weighIn;

  ReminderSettings with_(ReminderKind kind, bool on) => ReminderSettings(
    meals: kind == ReminderKind.meals ? on : meals,
    water: kind == ReminderKind.water ? on : water,
    weighIn: kind == ReminderKind.weighIn ? on : weighIn,
  );
}

/// Slots in plan order; their index makes the meal reminder id.
const reminderSlots = <String>['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'];

/// 09:00 to 21:00 every 2 hours: 7 a day.
const waterHours = <int>[9, 11, 13, 15, 17, 19, 21];
const weighInWeekday = DateTime.friday;
const weighInHour = 9;

const mealIdBase = 100;
const waterIdBase = 200;
const weighInId = 300;

/// One repeating notification: daily at [hour]:[minute], or weekly on
/// [weekday] when it is set.
class ReminderSpec {
  const ReminderSpec({
    required this.id,
    required this.kind,
    required this.hour,
    required this.minute,
    required this.route,
    this.slot,
    this.weekday,
  });

  final int id;
  final ReminderKind kind;
  final int hour;
  final int minute;

  /// Opened when the notification is tapped.
  final String route;

  /// The meal slot of a meal reminder.
  final String? slot;
  final int? weekday;
}

/// What to schedule. [mealStarts] maps a slot to the start of its window
/// in minutes after midnight; water needs a goal.
List<ReminderSpec> planReminders(
  ReminderSettings settings, {
  required Map<String, int> mealStarts,
  required bool hasWaterGoal,
}) {
  final specs = <ReminderSpec>[];
  if (settings.meals) {
    for (var index = 0; index < reminderSlots.length; index++) {
      final slot = reminderSlots[index];
      final start = mealStarts[slot];
      if (start == null) {
        continue;
      }
      specs.add(
        ReminderSpec(
          id: mealIdBase + index,
          kind: ReminderKind.meals,
          hour: start ~/ 60,
          minute: start % 60,
          route: '/today',
          slot: slot,
        ),
      );
    }
  }
  if (settings.water && hasWaterGoal) {
    for (var index = 0; index < waterHours.length; index++) {
      specs.add(
        ReminderSpec(
          id: waterIdBase + index,
          kind: ReminderKind.water,
          hour: waterHours[index],
          minute: 0,
          route: '/water',
        ),
      );
    }
  }
  if (settings.weighIn) {
    specs.add(
      const ReminderSpec(
        id: weighInId,
        kind: ReminderKind.weighIn,
        hour: weighInHour,
        minute: 0,
        route: '/progress',
        weekday: weighInWeekday,
      ),
    );
  }
  return specs;
}

/// "HH:MM" -> minutes after midnight, or null.
int? clockMinutes(String text) {
  final parts = text.split(':');
  if (parts.length < 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  return hour * 60 + minute;
}
