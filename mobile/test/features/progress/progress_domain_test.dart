import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/progress/data/progress_providers.dart';
import 'package:nutriguide/features/progress/domain/progress.dart';

AdherenceDay _day(
  String date, {
  String? status,
  int logs = 3,
  double? kcal,
  double? target = 1540,
  double protein = 100,
  double carb = 150,
  double fat = 50,
  List<MinimumAmount> unmet = const <MinimumAmount>[],
  List<LimitAmount> exceeded = const <LimitAmount>[],
}) {
  return AdherenceDay(
    date: date,
    status: status,
    logCount: logs,
    planItemsTotal: 4,
    planItemsConsumed: logs,
    kcal: kcal,
    targetKcal: target,
    proteinG: protein,
    carbG: carb,
    fatG: fat,
    unmet: unmet,
    exceeded: exceeded,
  );
}

const _dates = <String>[
  '2026-10-19',
  '2026-10-20',
  '2026-10-21',
  '2026-10-22',
  '2026-10-23',
  '2026-10-24',
  '2026-10-25',
];

void main() {
  final days = <String, AdherenceDay>{
    '2026-10-19': _day(
      '2026-10-19',
      status: 'ACHIEVED',
      kcal: 1600,
      unmet: const <MinimumAmount>[
        MinimumAmount(nutrient: 'fiber', minimum: 22, total: 18),
      ],
    ),
    '2026-10-20': _day(
      '2026-10-20',
      status: 'ACHIEVED',
      kcal: 1530,
      protein: 120,
      unmet: const <MinimumAmount>[
        MinimumAmount(nutrient: 'fiber', minimum: 22, total: 14),
        MinimumAmount(nutrient: 'protein', minimum: 110, total: 100),
      ],
    ),
    '2026-10-21': _day(
      '2026-10-21',
      status: 'PARTIAL',
      kcal: 1200,
      exceeded: const <LimitAmount>[
        LimitAmount(nutrient: 'sodium', limit: 2000, total: 2300),
      ],
    ),
    '2026-10-22': _day(
      '2026-10-22',
      status: 'NOT_ACHIEVED',
      kcal: 900,
      exceeded: const <LimitAmount>[
        LimitAmount(nutrient: 'sodium', limit: 2000, total: 2600),
        LimitAmount(nutrient: 'sugars', limit: 50, total: 61),
      ],
    ),
    // No log: excluded from the ratio even with a status.
    '2026-10-23': _day('2026-10-23', status: 'NOT_ACHIEVED', logs: 0),
  };

  test('adherence ratio counts logged days with a status only', () {
    final report = weekReport(dates: _dates, days: days);
    expect(report.achieved, 2);
    expect(report.counted, 4);
    expect(report.ratio, 0.5);
    expect(report.headline, WeekHeadline.good);
    expect(report.empty, isFalse);
    expect(report.bars, hasLength(7));
    expect(report.bars[4].tone, DayTone.none);
    expect(report.bars[4].kcal, isNull);
    expect(report.bars[6].tone, DayTone.none);
  });

  test('best day is the ACHIEVED day closest to its target', () {
    final best = weekReport(dates: _dates, days: days).bestDay!;
    expect(best.day.date, '2026-10-20');
    expect(best.percentOfTarget, closeTo(1530 / 1540 * 100, 1e-9));
  });

  test('most missed nutrient with its average total and minimum', () {
    final missed = weekReport(dates: _dates, days: days).mostMissed!;
    expect(missed.nutrient, 'fiber');
    expect(missed.days, 2);
    expect(missed.averageTotal, 16);
    expect(missed.averageMinimum, 22);
  });

  test('water average skips days without water', () {
    final report = weekReport(
      dates: _dates,
      days: days,
      waterByDate: const <String, int>{
        '2026-10-19': 1500,
        '2026-10-20': 2000,
        '2026-10-21': 0,
      },
    );
    expect(report.waterAverageMl, 1750);
    expect(weekReport(dates: _dates, days: days).waterAverageMl, isNull);
  });

  test('macro averages are over logged days only', () {
    final macros = weekReport(dates: _dates, days: days).macros!;
    expect(macros.proteinG, (100 + 120 + 100 + 100) / 4);
    expect(macros.carbG, 150);
    expect(macros.fatG, 50);
  });

  test('exceeded limits: days and the highest total per nutrient', () {
    final exceeded = weekReport(dates: _dates, days: days).exceeded!;
    expect(exceeded.days, 2);
    final sodium = exceeded.limits.firstWhere((l) => l.nutrient == 'sodium');
    expect(sodium.total, 2600);
    expect(sodium.limit, 2000);
    expect(exceeded.limits.map((l) => l.nutrient), contains('sugars'));
  });

  test('a week without logs is empty and has no ratio', () {
    final report = weekReport(
      dates: _dates,
      days: <String, AdherenceDay>{'2026-10-23': _day('2026-10-23', logs: 0)},
    );
    expect(report.empty, isTrue);
    expect(report.ratio, isNull);
    expect(report.headline, isNull);
    expect(report.bestDay, isNull);
    expect(report.macros, isNull);
  });

  test('general mode: no target line and gray bars', () {
    final report = weekReport(
      dates: _dates,
      days: <String, AdherenceDay>{
        '2026-10-25': _day('2026-10-25', kcal: 1800, target: null),
      },
    );
    expect(report.targetKcal, isNull);
    expect(report.counted, 0);
    expect(report.bars.last.kcal, 1800);
    expect(report.bars.last.tone, DayTone.none);
  });

  test('headline thresholds', () {
    WeekReport only(int achieved, int counted) {
      return WeekReport(
        dates: _dates,
        bars: const <WeekBar>[],
        achieved: achieved,
        counted: counted,
        empty: false,
      );
    }

    expect(only(4, 5).headline, WeekHeadline.excellent);
    expect(only(3, 5).headline, WeekHeadline.good);
    expect(only(2, 5).headline, WeekHeadline.fresh);
  });

  test('week navigation stays within 0 and 12 weeks back', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final offset = container.read(weekOffsetProvider.notifier);
    offset.newer();
    expect(container.read(weekOffsetProvider), 0);
    for (var step = 0; step < 20; step++) {
      offset.older();
    }
    expect(container.read(weekOffsetProvider), maxWeeksBack);
    final dates = weekEnding(DateTime(2026, 10, 25), 1);
    expect(dates.first, DateTime(2026, 10, 12));
    expect(dates.last, DateTime(2026, 10, 18));
  });

  test('weight tiles, signed change and the maintenance label', () {
    final points = <WeightPointView>[
      WeightPointView(date: DateTime(2026, 10, 25), weightKg: 78.5),
      WeightPointView(date: DateTime(2026, 10, 1), weightKg: 80),
    ];
    final lose = weightSummary(
      points: points,
      goalType: 'LOSE',
      targetWeightKg: 75,
    );
    expect(lose.start!.weightKg, 80);
    expect(lose.latest!.weightKg, 78.5);
    expect(lose.change, closeTo(-1.5, 1e-9));
    expect(lose.targetKg, 75);
    expect(lose.maintenance, isFalse);
    expect(lose.enough, isTrue);

    final keep = weightSummary(
      points: points,
      goalType: 'MAINTAIN',
      targetWeightKg: 75,
    );
    expect(keep.maintenance, isTrue);
    expect(keep.targetKg, isNull);

    final single = weightSummary(
      points: points.take(1).toList(),
      goalType: 'LOSE',
    );
    expect(single.enough, isFalse);
    expect(single.change, isNull);
  });

  test('axis ticks are round and cover the range', () {
    final ticks = axisTicks(74.6, 80.2);
    expect(ticks.first, lessThanOrEqualTo(74.6));
    expect(ticks.last, greaterThanOrEqualTo(80.2));
    expect(ticks.length, inInclusiveRange(4, 6));
    for (final tick in ticks) {
      expect(tick * 2, (tick * 2).roundToDouble());
    }
  });
}
