/// Progress tab domain (Decisions #276 to #282). Every number comes from
/// the server; this file only counts days, averages server values and picks
/// the largest or smallest among them.
library;

class LimitAmount {
  const LimitAmount({required this.nutrient, required this.limit, this.total});

  final String nutrient;
  final double limit;
  final double? total;
}

class MinimumAmount {
  const MinimumAmount({
    required this.nutrient,
    required this.minimum,
    this.total,
  });

  final String nutrient;
  final double minimum;
  final double? total;
}

/// One day of `GET /adherence`.
class AdherenceDay {
  const AdherenceDay({
    required this.date,
    required this.logCount,
    required this.planItemsTotal,
    required this.planItemsConsumed,
    this.status,
    this.completion,
    this.targetKcal,
    this.kcal,
    this.proteinG,
    this.carbG,
    this.fatG,
    this.unmet = const <MinimumAmount>[],
    this.exceeded = const <LimitAmount>[],
    this.reason,
  });

  /// YYYY-MM-DD.
  final String date;

  /// ACHIEVED, PARTIAL, NOT_ACHIEVED, or null.
  final String? status;
  final double? completion;
  final double? targetKcal;
  final double? kcal;
  final double? proteinG;
  final double? carbG;
  final double? fatG;
  final List<MinimumAmount> unmet;
  final List<LimitAmount> exceeded;
  final int planItemsTotal;
  final int planItemsConsumed;
  final int logCount;
  final String? reason;

  bool get logged => logCount > 0;
}

/// The colour group of a day.
enum DayTone { achieved, partial, notAchieved, none }

DayTone toneOf(AdherenceDay? day) {
  if (day == null || !day.logged) {
    return DayTone.none;
  }
  return switch (day.status) {
    'ACHIEVED' => DayTone.achieved,
    'PARTIAL' => DayTone.partial,
    'NOT_ACHIEVED' => DayTone.notAchieved,
    _ => DayTone.none,
  };
}

enum WeekHeadline { excellent, good, fresh }

class BestDay {
  const BestDay({required this.day, required this.percentOfTarget});

  final AdherenceDay day;

  /// kcal ÷ target_kcal × 100, both server numbers.
  final double percentOfTarget;
}

class MostMissed {
  const MostMissed({
    required this.nutrient,
    required this.days,
    required this.averageTotal,
    required this.averageMinimum,
  });

  final String nutrient;
  final int days;
  final double averageTotal;
  final double averageMinimum;
}

class MacroAverages {
  const MacroAverages({
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  final double proteinG;
  final double carbG;
  final double fatG;
}

class ExceededSummary {
  const ExceededSummary({required this.days, required this.limits});

  /// Days with at least one exceeded limit.
  final int days;

  /// One entry per nutrient: the day where its total was highest.
  final List<LimitAmount> limits;
}

class WeekBar {
  const WeekBar({required this.date, required this.tone, this.kcal});

  final String date;
  final double? kcal;
  final DayTone tone;
}

class WeekReport {
  const WeekReport({
    required this.dates,
    required this.bars,
    required this.achieved,
    required this.counted,
    required this.empty,
    this.targetKcal,
    this.bestDay,
    this.mostMissed,
    this.waterAverageMl,
    this.macros,
    this.exceeded,
  });

  /// The seven dates, oldest first.
  final List<String> dates;
  final List<WeekBar> bars;

  /// Days with status ACHIEVED.
  final int achieved;

  /// Logged days with a status; no-log days are not counted.
  final int counted;

  /// No day of the week has a log.
  final bool empty;

  /// The target line of the chart: the latest server target in the week.
  final double? targetKcal;
  final BestDay? bestDay;
  final MostMissed? mostMissed;
  final int? waterAverageMl;
  final MacroAverages? macros;
  final ExceededSummary? exceeded;

  double? get ratio => counted == 0 ? null : achieved / counted;

  WeekHeadline? get headline {
    final value = ratio;
    if (value == null) {
      return null;
    }
    if (value >= 0.8) {
      return WeekHeadline.excellent;
    }
    if (value >= 0.5) {
      return WeekHeadline.good;
    }
    return WeekHeadline.fresh;
  }
}

/// [days] are the cached rows; [dates] the seven dates of the week, oldest
/// first; [waterByDate] the confirmed water of each date that has any.
WeekReport weekReport({
  required List<String> dates,
  required Map<String, AdherenceDay> days,
  Map<String, int> waterByDate = const <String, int>{},
}) {
  final week = <AdherenceDay>[
    for (final date in dates)
      if (days[date] != null) days[date]!,
  ];
  final logged = week.where((AdherenceDay day) => day.logged).toList();
  var achieved = 0;
  var counted = 0;
  for (final day in logged) {
    if (day.status == null) {
      continue;
    }
    counted += 1;
    if (day.status == 'ACHIEVED') {
      achieved += 1;
    }
  }

  double? target;
  for (final day in week) {
    target = day.targetKcal ?? target;
  }

  BestDay? best;
  for (final day in logged) {
    final kcal = day.kcal;
    final goal = day.targetKcal;
    if (day.status != 'ACHIEVED' || kcal == null || goal == null || goal <= 0) {
      continue;
    }
    final gap = (kcal - goal).abs();
    final current = best;
    if (current == null ||
        gap < (current.day.kcal! - current.day.targetKcal!).abs()) {
      best = BestDay(day: day, percentOfTarget: kcal / goal * 100);
    }
  }

  final missedCounts = <String, List<MinimumAmount>>{};
  for (final day in logged) {
    for (final unmet in day.unmet) {
      missedCounts
          .putIfAbsent(unmet.nutrient, () => <MinimumAmount>[])
          .add(unmet);
    }
  }
  MostMissed? missed;
  for (final entry in missedCounts.entries) {
    if (missed != null && entry.value.length <= missed.days) {
      continue;
    }
    final totals = <double>[
      for (final unmet in entry.value)
        if (unmet.total != null) unmet.total!,
    ];
    missed = MostMissed(
      nutrient: entry.key,
      days: entry.value.length,
      averageTotal: totals.isEmpty
          ? 0
          : totals.reduce((double a, double b) => a + b) / totals.length,
      averageMinimum:
          entry.value
              .map((MinimumAmount unmet) => unmet.minimum)
              .reduce((double a, double b) => a + b) /
          entry.value.length,
    );
  }

  final water = <int>[
    for (final date in dates)
      if ((waterByDate[date] ?? 0) > 0) waterByDate[date]!,
  ];

  MacroAverages? macros;
  if (logged.isNotEmpty) {
    double average(double? Function(AdherenceDay day) pick) {
      final values = <double>[
        for (final day in logged)
          if (pick(day) != null) pick(day)!,
      ];
      return values.isEmpty
          ? 0
          : values.reduce((double a, double b) => a + b) / values.length;
    }

    macros = MacroAverages(
      proteinG: average((AdherenceDay day) => day.proteinG),
      carbG: average((AdherenceDay day) => day.carbG),
      fatG: average((AdherenceDay day) => day.fatG),
    );
  }

  final exceededDays = logged
      .where((AdherenceDay day) => day.exceeded.isNotEmpty)
      .toList();
  ExceededSummary? exceeded;
  if (exceededDays.isNotEmpty) {
    final highest = <String, LimitAmount>{};
    for (final day in exceededDays) {
      for (final limit in day.exceeded) {
        final current = highest[limit.nutrient];
        if (current == null ||
            (limit.total ?? 0) > (current.total ?? double.negativeInfinity)) {
          highest[limit.nutrient] = limit;
        }
      }
    }
    exceeded = ExceededSummary(
      days: exceededDays.length,
      limits: highest.values.toList(),
    );
  }

  return WeekReport(
    dates: dates,
    bars: <WeekBar>[
      for (final date in dates)
        WeekBar(
          date: date,
          kcal: days[date]?.logged ?? false ? days[date]!.kcal : null,
          tone: toneOf(days[date]),
        ),
    ],
    achieved: achieved,
    counted: counted,
    empty: logged.isEmpty,
    targetKcal: target,
    bestDay: best,
    mostMissed: missed,
    waterAverageMl: water.isEmpty
        ? null
        : (water.reduce((int a, int b) => a + b) / water.length).round(),
    macros: macros,
    exceeded: exceeded,
  );
}

/// The furthest week back the report offers.
const maxWeeksBack = 12;

/// The seven dates ending [weeksBack] weeks before [today], oldest first.
List<DateTime> weekEnding(DateTime today, int weeksBack) {
  final end = DateTime(today.year, today.month, today.day - 7 * weeksBack);
  return <DateTime>[
    for (var offset = 6; offset >= 0; offset--)
      DateTime(end.year, end.month, end.day - offset),
  ];
}

class WeightPointView {
  const WeightPointView({required this.date, required this.weightKg});

  final DateTime date;
  final double weightKg;
}

class WeightSummary {
  const WeightSummary({
    required this.points,
    required this.maintenance,
    this.start,
    this.latest,
    this.targetKg,
  });

  /// In the range, oldest first.
  final List<WeightPointView> points;
  final WeightPointView? start;
  final WeightPointView? latest;

  /// The goal weight; null without one.
  final double? targetKg;

  /// MAINTAIN: the goal tile shows «الحفاظ» and the latest weight.
  final bool maintenance;

  /// Latest minus first; null with fewer than two points.
  double? get change {
    final first = start;
    final last = latest;
    if (first == null || last == null || points.length < 2) {
      return null;
    }
    return last.weightKg - first.weightKg;
  }

  bool get enough => points.length >= 2;
}

WeightSummary weightSummary({
  required List<WeightPointView> points,
  required String? goalType,
  double? targetWeightKg,
}) {
  final sorted = <WeightPointView>[...points]
    ..sort((WeightPointView a, WeightPointView b) => a.date.compareTo(b.date));
  final maintenance = goalType == 'MAINTAIN';
  return WeightSummary(
    points: sorted,
    start: sorted.isEmpty ? null : sorted.first,
    latest: sorted.isEmpty ? null : sorted.last,
    targetKg: maintenance ? null : targetWeightKg,
    maintenance: maintenance,
  );
}

/// Four to five round ticks that cover [low]..[high].
List<double> axisTicks(double low, double high) {
  if (high <= low) {
    final base = low.floorToDouble();
    return <double>[base - 1, base, base + 1];
  }
  final span = high - low;
  const steps = <double>[0.5, 1, 2, 5, 10, 20, 50];
  var step = steps.last;
  for (final candidate in steps) {
    if (span / candidate <= 4) {
      step = candidate;
      break;
    }
  }
  final first = (low / step).floorToDouble() * step;
  final last = (high / step).ceilToDouble() * step;
  return <double>[
    for (var tick = first; tick <= last + 1e-9; tick += step) tick,
  ];
}
