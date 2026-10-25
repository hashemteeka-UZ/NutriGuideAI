import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/db/app_database.dart' hide PlanItem;
import 'package:nutriguide/core/l10n/app_localizations_ar.dart';
import 'package:nutriguide/core/network/app_failure.dart';
import 'package:nutriguide/core/network/failure_message.dart';
import 'package:nutriguide/features/plan/data/plan_api.dart';
import 'package:nutriguide/features/plan/data/plan_mapper.dart';
import 'package:nutriguide/features/plan/data/plan_repository.dart';
import 'package:nutriguide/features/plan/domain/plan.dart';
import 'package:nutriguide/features/plan/domain/plan_dates.dart';

import '../../support/plan_samples.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('refresh replaces the range and keeps days outside it', () async {
    final now = DateTime(2026, 10, 24, 9);
    final range = planCacheRange(now);
    final outside = sampleDay(
      planDate: '2026-09-01',
      planId: 9,
      items: <PlanItem>[sampleItem(planItemId: 9, planDate: '2026-09-01')],
    );
    final stale = sampleDay(
      planDate: isoDate(range.from),
      planId: 2,
      items: <PlanItem>[
        sampleItem(planItemId: 2, planDate: isoDate(range.from)),
      ],
    );
    final api = _FakePlanApi(
      listed: <DayPlan>[
        sampleDay(
          planDate: isoDate(range.to),
          planId: 3,
          items: <PlanItem>[
            sampleItem(planItemId: 3, planDate: isoDate(range.to)),
          ],
        ),
      ],
    );
    final repository = PlanRepository(
      database,
      api,
      locale: () => 'ar',
      now: () => now,
    );
    await repository.storeDay(outside);
    await repository.storeDay(stale);

    await repository.refresh();

    final dates = (await database.select(database.plans).get())
        .map((Plan row) => row.planDate)
        .toList();
    expect(dates, containsAll(<String>['2026-09-01', isoDate(range.to)]));
    expect(dates, isNot(contains(isoDate(range.from))));
  });

  test('concurrent refresh calls share one request', () async {
    final now = DateTime(2026, 10, 24, 9);
    final api = _FakePlanApi(
      listed: <DayPlan>[sampleDay(planDate: '2026-10-24')],
    );
    final repository = PlanRepository(
      database,
      api,
      locale: () => 'ar',
      now: () => now,
    );
    await Future.wait<void>(<Future<void>>[
      repository.refresh(),
      repository.refresh(),
    ]);
    expect(api.listCalls, 1);
  });

  test('mapper round trip keeps null totals and null stats', () async {
    final day = sampleDay(
      planDate: '2026-10-24',
      totalsKcal: null,
      stats: null,
    );
    final fetched = DateTime.utc(2026, 10, 24, 8);
    await database.into(database.plans).insert(planCompanion(day, fetched));
    for (final item in day.items) {
      await database.into(database.planItems).insert(itemCompanion(item));
    }
    final row = await database.select(database.plans).getSingle();
    final items = await database.select(database.planItems).get();
    final read = dayPlanFromRows(
      row: row,
      items: items,
      unmet: const <PlanUnmetMinimum>[],
    );
    expect(read.totals.kcal, isNull);
    expect(read.stats, isNull);
    expect(read.items.single.mealName, 'فول');
    expect(read.target.kcal, 1800);
  });

  test('swap success updates the item and refreshes', () async {
    final now = DateTime(2026, 10, 24, 9);
    final original = sampleDay(planDate: '2026-10-24');
    final api = _FakePlanApi(
      listed: <DayPlan>[
        sampleDay(
          planDate: '2026-10-24',
          items: <PlanItem>[sampleItem(mealId: 99, mealName: 'عدس', kcal: 360)],
          totalsKcal: 1700,
        ),
      ],
      swapped: sampleItem(mealId: 99, mealName: 'عدس', kcal: 360),
    );
    final repository = PlanRepository(
      database,
      api,
      locale: () => 'ar',
      now: () => now,
    );
    await repository.storeDay(original);
    final updated = await repository.swap(planItemId: 1, mealId: 99);
    expect(updated.mealName, 'عدس');
    final stored = await repository.readRange('2026-10-24', '2026-10-24');
    expect(stored.single.items.single.mealName, 'عدس');
    expect(stored.single.items.single.kcal, 360);
    expect(api.listCalls, 1);
  });

  test('SWAP_REJECTED leaves the cache unchanged', () async {
    final now = DateTime(2026, 10, 24, 9);
    final api = _FakePlanApi(
      reject: const PlanRequestException(code: 'SWAP_REJECTED'),
    );
    final repository = PlanRepository(
      database,
      api,
      locale: () => 'ar',
      now: () => now,
    );
    await repository.storeDay(sampleDay(planDate: '2026-10-24'));
    await expectLater(
      repository.swap(planItemId: 1, mealId: 2),
      throwsA(
        isA<PlanRequestException>().having(
          (PlanRequestException error) => error.code,
          'code',
          'SWAP_REJECTED',
        ),
      ),
    );
    final stored = await repository.readRange('2026-10-24', '2026-10-24');
    expect(stored.single.items.single.mealName, 'فول');
    expect(api.listCalls, 0);
  });

  test('PLAN_ITEM_ALREADY_LOGGED message', () {
    final message = failureMessage(
      AppLocalizationsAr(),
      const ApiProblem(
        status: 409,
        code: 'PLAN_ITEM_ALREADY_LOGGED',
        title: null,
        detail: null,
        requestId: null,
        retryAfter: null,
      ),
    );
    expect(message, 'سجلت هذه الوجبة، لا يمكن استبدالها.');
  });
}

class _FakePlanApi extends PlanApi {
  _FakePlanApi({this.listed = const <DayPlan>[], this.swapped, this.reject})
    : super(Dio());

  final List<DayPlan> listed;
  final PlanItem? swapped;
  final PlanRequestException? reject;
  int listCalls = 0;

  @override
  Future<List<DayPlan>> listPlans({
    required DateTime from,
    required DateTime to,
  }) async {
    listCalls += 1;
    return listed;
  }

  @override
  Future<PlanItem> swap({required int planItemId, required int mealId}) async {
    final error = reject;
    if (error != null) {
      throw error;
    }
    return swapped ?? sampleItem(mealId: mealId);
  }
}
