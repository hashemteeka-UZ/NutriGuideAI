import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/plan/domain/plan.dart';
import 'package:nutriguide/features/plan/domain/plan_dates.dart';
import 'package:nutriguide/features/plan/domain/week_generator.dart';

import '../../support/plan_samples.dart';

void main() {
  final today = DateTime(2026, 10, 24);

  WeekGenerator generator({
    required Future<DayPlan> Function(DateTime date) createDay,
    Future<bool> Function(DateTime date)? isLogged,
    List<Duration>? waits,
    List<DayPlan>? stored,
  }) {
    return WeekGenerator(
      createDay: createDay,
      isLogged: isLogged ?? (DateTime date) async => false,
      storeDay: (DayPlan plan) async {
        stored?.add(plan);
      },
      now: () => today,
      wait: (Duration duration) async {
        waits?.add(duration);
      },
    );
  }

  DayPlan ok(DateTime date) {
    return sampleDay(planDate: isoDate(date), stats: sampleStats());
  }

  test('seven successes stay in order', () async {
    final calls = <String>[];
    final events = await generator(
      createDay: (DateTime date) async {
        calls.add(isoDate(date));
        return ok(date);
      },
    ).run().toList();
    expect(calls, <String>[
      '2026-10-24',
      '2026-10-25',
      '2026-10-26',
      '2026-10-27',
      '2026-10-28',
      '2026-10-29',
      '2026-10-30',
    ]);
    final done = events.whereType<WeekDateDone>().toList();
    expect(done, hasLength(7));
    expect(done.map((WeekDateDone event) => event.plan.planDate), calls);
    final finished = events.whereType<WeekFinished>().single;
    expect(finished.built, 7);
    expect(finished.stopped, isFalse);
  });

  test('PLANNER_BUSY waits for Retry-After then succeeds', () async {
    final waits = <Duration>[];
    var calls = 0;
    final events = await generator(
      waits: waits,
      createDay: (DateTime date) async {
        calls += 1;
        if (calls == 1) {
          throw const PlanRequestException(
            code: 'PLANNER_BUSY',
            retryAfterSeconds: 2,
          );
        }
        return ok(date);
      },
    ).run().toList();
    expect(waits, <Duration>[const Duration(seconds: 2)]);
    expect(events.whereType<WeekDateDone>(), hasLength(7));
    expect(calls, 8);
  });

  test('three PLANNER_BUSY replies stop without another wait', () async {
    final waits = <Duration>[];
    var calls = 0;
    final events = await generator(
      waits: waits,
      createDay: (DateTime date) async {
        calls += 1;
        throw const PlanRequestException(
          code: 'PLANNER_BUSY',
          retryAfterSeconds: 5,
        );
      },
    ).run().toList();
    expect(calls, 3);
    expect(waits, hasLength(2));
    final finished = events.whereType<WeekFinished>().single;
    expect(finished.stopped, isTrue);
    expect(finished.stopCode, 'PLANNER_BUSY');
    expect(finished.built, 0);
  });

  test('PLANNER_TIMEOUT stops and keeps days already built', () async {
    final stored = <DayPlan>[];
    final events = await generator(
      stored: stored,
      createDay: (DateTime date) async {
        if (isoDate(date) == '2026-10-25') {
          throw const PlanRequestException(code: 'PLANNER_TIMEOUT');
        }
        return ok(date);
      },
    ).run().toList();
    expect(stored, hasLength(1));
    expect(stored.single.planDate, '2026-10-24');
    final finished = events.whereType<WeekFinished>().single;
    expect(finished.stopCode, 'PLANNER_TIMEOUT');
    expect(finished.built, 1);
  });

  test('RATE_LIMITED stops', () async {
    final events = await generator(
      createDay: (DateTime date) async {
        throw const PlanRequestException(
          code: 'RATE_LIMITED',
          retryAfterSeconds: 12,
        );
      },
    ).run().toList();
    final finished = events.whereType<WeekFinished>().single;
    expect(finished.stopCode, 'RATE_LIMITED');
    expect(finished.retryAfterSeconds, 12);
    expect(finished.built, 0);
  });

  test('NO_FEASIBLE_PLAN on day 3 continues', () async {
    final events = await generator(
      createDay: (DateTime date) async {
        if (isoDate(date) == '2026-10-26') {
          throw const PlanRequestException(code: 'NO_FEASIBLE_PLAN');
        }
        return ok(date);
      },
    ).run().toList();
    final failed = events.whereType<WeekDateFailed>().single;
    expect(isoDate(failed.date), '2026-10-26');
    expect(failed.code, 'NO_FEASIBLE_PLAN');
    final finished = events.whereType<WeekFinished>().single;
    expect(finished.built, 6);
    expect(finished.failedDates, hasLength(1));
    expect(finished.stopped, isFalse);
  });

  test('a logged day is skipped', () async {
    final calls = <String>[];
    final events = await generator(
      isLogged: (DateTime date) async => isoDate(date) == '2026-10-25',
      createDay: (DateTime date) async {
        calls.add(isoDate(date));
        return ok(date);
      },
    ).run().toList();
    expect(calls, isNot(contains('2026-10-25')));
    expect(calls, hasLength(6));
    expect(events.whereType<WeekDateStarted>(), hasLength(6));
    expect(events.whereType<WeekFinished>().single.built, 6);
  });

  test('NOT_ELIGIBLE stops', () async {
    final events = await generator(
      createDay: (DateTime date) async {
        throw const PlanRequestException(code: 'NOT_ELIGIBLE');
      },
    ).run().toList();
    final finished = events.whereType<WeekFinished>().single;
    expect(finished.stopCode, 'NOT_ELIGIBLE');
    expect(finished.stopped, isTrue);
    expect(events.whereType<WeekDateDone>(), isEmpty);
  });
}
