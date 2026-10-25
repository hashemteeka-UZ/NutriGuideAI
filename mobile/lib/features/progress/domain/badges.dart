import '../../plan/domain/plan_dates.dart';

/// Badges computed on the phone from local tables only (#305, #307).
enum BadgeCode {
  firstLog('FIRST_LOG'),
  firstAchievedDay('FIRST_ACHIEVED_DAY'),
  streak3('STREAK_3'),
  streak7('STREAK_7'),
  streak14('STREAK_14'),
  streak30('STREAK_30'),
  balancedWeek('BALANCED_WEEK'),
  waterGoal3('WATER_GOAL_3'),
  weightTracker('WEIGHT_TRACKER'),
  explorer10('EXPLORER_10');

  const BadgeCode(this.code);

  final String code;

  static BadgeCode? fromCode(String code) {
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }
    return null;
  }
}

/// What the rules read. Dates are YYYY-MM-DD strings.
class BadgeInputs {
  const BadgeInputs({
    this.loggedMealIds = const <int?>[],
    this.dayStatuses = const <String, String?>{},
    this.waterByDate = const <String, int>{},
    this.waterGoalByDate = const <String, int?>{},
    this.latestWaterGoal,
    this.weightDates = const <String>[],
  });

  /// One entry per consumption log that is not deleted (PENDING or
  /// CONFIRMED); null for a log without a catalog meal.
  final List<int?> loggedMealIds;

  /// Server status of each cached adherence day (K.6a).
  final Map<String, String?> dayStatuses;

  /// Water drunk per date.
  final Map<String, int> waterByDate;

  /// The goal that applied on a date, when the day summary knows it.
  final Map<String, int?> waterGoalByDate;

  /// The last known goal, used for dates without their own.
  final int? latestWaterGoal;

  /// One per stored weight.
  final List<String> weightDates;
}

class BadgeProgress {
  const BadgeProgress({
    required this.code,
    required this.current,
    required this.target,
    this.needsWaterGoal = false,
  });

  final BadgeCode code;

  /// Capped at [target] for display.
  final int current;
  final int target;

  /// WATER_GOAL_3 without any goal: the UI shows a hint instead of progress.
  final bool needsWaterGoal;

  bool get earned => current >= target;
}

const achievedStatus = 'ACHIEVED';
const weightTrackerEntries = 4;
const weightTrackerSpanDays = 21;
const balancedWeekDays = 5;
const _window = 7;

List<DateTime> _achievedDates(Map<String, String?> statuses) {
  final dates = <DateTime>[
    for (final entry in statuses.entries)
      if (entry.value == achievedStatus) dateFromIso(entry.key),
  ]..sort();
  return dates;
}

int _daysBetween(DateTime a, DateTime b) {
  return DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}

/// Longest run of consecutive achieved dates, as the K.6a streak counts them.
int longestAchievedRun(Map<String, String?> statuses) {
  final dates = _achievedDates(statuses);
  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final date in dates) {
    run = previous != null && _daysBetween(previous, date) == 1 ? run + 1 : 1;
    if (run > best) {
      best = run;
    }
    previous = date;
  }
  return best;
}

/// Most achieved days in any 7 consecutive dates.
int bestSevenDayWindow(Map<String, String?> statuses) {
  final dates = _achievedDates(statuses);
  var best = 0;
  for (var start = 0; start < dates.length; start++) {
    var count = 0;
    for (var index = start; index < dates.length; index++) {
      if (_daysBetween(dates[start], dates[index]) >= _window) {
        break;
      }
      count += 1;
    }
    if (count > best) {
      best = count;
    }
  }
  return best;
}

BadgeProgress _progress(BadgeCode code, int value, int target) {
  return BadgeProgress(
    code: code,
    current: value > target ? target : value,
    target: target,
  );
}

/// Every badge with its progress, in display order.
List<BadgeProgress> evaluateBadges(BadgeInputs inputs) {
  final run = longestAchievedRun(inputs.dayStatuses);
  final achieved = _achievedDates(inputs.dayStatuses).length;

  final hasGoal =
      inputs.latestWaterGoal != null ||
      inputs.waterGoalByDate.values.any((int? goal) => goal != null);
  var waterDays = 0;
  for (final entry in inputs.waterByDate.entries) {
    final goal = inputs.waterGoalByDate[entry.key] ?? inputs.latestWaterGoal;
    if (goal != null && goal > 0 && entry.value >= goal) {
      waterDays += 1;
    }
  }

  final weights = <DateTime>[
    for (final date in inputs.weightDates.toSet()) dateFromIso(date),
  ]..sort();
  final weightSpan = weights.length < 2
      ? 0
      : _daysBetween(weights.first, weights.last);
  final weightEarned =
      weights.length >= weightTrackerEntries &&
      weightSpan >= weightTrackerSpanDays;

  return <BadgeProgress>[
    _progress(BadgeCode.firstLog, inputs.loggedMealIds.length, 1),
    _progress(BadgeCode.firstAchievedDay, achieved, 1),
    _progress(BadgeCode.streak3, run, 3),
    _progress(BadgeCode.streak7, run, 7),
    _progress(BadgeCode.streak14, run, 14),
    _progress(BadgeCode.streak30, run, 30),
    _progress(
      BadgeCode.balancedWeek,
      bestSevenDayWindow(inputs.dayStatuses),
      balancedWeekDays,
    ),
    BadgeProgress(
      code: BadgeCode.waterGoal3,
      current: waterDays > 3 ? 3 : waterDays,
      target: 3,
      needsWaterGoal: !hasGoal,
    ),
    BadgeProgress(
      code: BadgeCode.weightTracker,
      // Four entries close together are not yet a habit: hold at 3 of 4
      // until the first and last are 21 days apart.
      current: weightEarned
          ? weightTrackerEntries
          : (weights.length >= weightTrackerEntries
                ? weightTrackerEntries - 1
                : weights.length),
      target: weightTrackerEntries,
    ),
    _progress(
      BadgeCode.explorer10,
      inputs.loggedMealIds.whereType<int>().toSet().length,
      10,
    ),
  ];
}
