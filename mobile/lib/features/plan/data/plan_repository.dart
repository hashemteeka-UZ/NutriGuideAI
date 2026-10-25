import 'dart:async';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart' as db;
import '../../catalog/domain/meal.dart';
import '../domain/plan.dart';
import '../domain/plan_dates.dart';
import 'plan_api.dart';
import 'plan_mapper.dart';

class PlanRepository {
  PlanRepository(
    this._database,
    this._api, {
    required this._locale,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final db.AppDatabase _database;
  final PlanApi _api;
  final String Function() _locale;
  final DateTime Function() _now;
  Future<void>? _refreshing;

  Future<void> refresh() {
    final current = _refreshing;
    if (current != null) {
      return current;
    }
    final future = _refresh();
    _refreshing = future;
    return future.whenComplete(() {
      if (identical(_refreshing, future)) {
        _refreshing = null;
      }
    });
  }

  Future<void> _refresh() async {
    final range = planCacheRange(_now());
    final days = await _api.listPlans(from: range.from, to: range.to);
    await replaceRange(
      from: isoDate(range.from),
      to: isoDate(range.to),
      days: days,
    );
  }

  Future<void> replaceRange({
    required String from,
    required String to,
    required List<DayPlan> days,
  }) async {
    final fetchedAt = _now().toUtc();
    await _database.transaction(() async {
      final existing =
          await (_database.select(_database.plans)..where(
                (t) =>
                    t.planDate.isBiggerOrEqualValue(from) &
                    t.planDate.isSmallerOrEqualValue(to),
              ))
              .get();
      for (final row in existing) {
        await (_database.delete(
          _database.plans,
        )..where((t) => t.planDate.equals(row.planDate))).go();
      }
      for (final day in days) {
        if (day.planDate.compareTo(from) < 0 ||
            day.planDate.compareTo(to) > 0) {
          continue;
        }
        await _insertDay(day, fetchedAt);
      }
    });
  }

  Future<void> storeDay(DayPlan day) async {
    final fetchedAt = _now().toUtc();
    await _database.transaction(() async {
      await (_database.delete(
        _database.plans,
      )..where((t) => t.planDate.equals(day.planDate))).go();
      await _insertDay(day, fetchedAt);
    });
  }

  Future<bool> dayHasLoggedItem(DateTime date) async {
    final rows =
        await (_database.select(_database.planItems)..where(
              (t) =>
                  t.planDate.equals(isoDate(dateOnly(date))) &
                  t.logged.equals(true),
            ))
            .get();
    return rows.isNotEmpty;
  }

  Future<void> applySwap(PlanItem item) async {
    final current = await (_database.select(
      _database.planItems,
    )..where((t) => t.planItemId.equals(item.planItemId))).getSingleOrNull();
    if (current == null) {
      return;
    }
    await _database.transaction(() async {
      await (_database.update(
        _database.planItems,
      )..where((t) => t.planItemId.equals(item.planItemId))).write(
        db.PlanItemsCompanion(
          slot: Value(item.slot.isEmpty ? current.slot : item.slot),
          mealId: Value(item.mealId),
          mealName: Value(item.mealName),
          servingsMultiplier: Value(item.servingsMultiplier),
          grams: Value(item.grams),
          kcal: Value(item.kcal),
          proteinG: Value(item.proteinG),
          carbG: Value(item.carbG),
          fatG: Value(item.fatG),
          reasonCodes: Value(encodeReasons(item.reasonCodes)),
          wasSwapped: Value(item.wasSwapped),
          logged: Value(item.logged),
        ),
      );
      await (_database.update(_database.plans)
            ..where((t) => t.planDate.equals(current.planDate)))
          .write(db.PlansCompanion(fetchedAt: Value(_now().toUtc())));
    });
  }

  Future<List<PlanAlternative>> alternatives(int planItemId) {
    return _api.alternatives(planItemId);
  }

  Future<PlanItem> swap({required int planItemId, required int mealId}) async {
    final item = await _api.swap(planItemId: planItemId, mealId: mealId);
    await applySwap(item);
    await refresh();
    return item;
  }

  Stream<List<DayPlan>> watchRange(String from, String to) {
    final plans =
        (_database.select(_database.plans)..where(
              (t) =>
                  t.planDate.isBiggerOrEqualValue(from) &
                  t.planDate.isSmallerOrEqualValue(to),
            ))
            .watch();
    final items = _database.select(_database.planItems).watch();
    return _merge(<Stream<Object?>>[plans, items], () => readRange(from, to));
  }

  Stream<DayPlan?> watchDay(String date) {
    return watchRange(date, date).map((List<DayPlan> days) {
      for (final day in days) {
        if (day.planDate == date) {
          return day;
        }
      }
      return null;
    });
  }

  Stream<PlanItem?> watchItem(int planItemId) {
    final items = (_database.select(
      _database.planItems,
    )..where((t) => t.planItemId.equals(planItemId))).watch();
    return _merge(<Stream<Object?>>[items], () async {
      final row = await (_database.select(
        _database.planItems,
      )..where((t) => t.planItemId.equals(planItemId))).getSingleOrNull();
      if (row == null) {
        return null;
      }
      final days = await readRange(row.planDate, row.planDate);
      for (final day in days) {
        for (final item in day.items) {
          if (item.planItemId == planItemId) {
            return item;
          }
        }
      }
      return null;
    });
  }

  Future<List<DayPlan>> readRange(String from, String to) async {
    final rows =
        await (_database.select(_database.plans)..where(
              (t) =>
                  t.planDate.isBiggerOrEqualValue(from) &
                  t.planDate.isSmallerOrEqualValue(to),
            ))
            .get();
    if (rows.isEmpty) {
      return const <DayPlan>[];
    }
    final dates = <String>[for (final row in rows) row.planDate];
    final items = await (_database.select(
      _database.planItems,
    )..where((t) => t.planDate.isIn(dates))).get();
    final unmet = await (_database.select(
      _database.planUnmetMinimums,
    )..where((t) => t.planDate.isIn(dates))).get();
    final catalog = await _catalog(<int>{
      for (final item in items) item.mealId,
    });
    return <DayPlan>[
      for (final row in rows)
        dayPlanFromRows(
          row: row,
          items: <db.PlanItem>[
            for (final item in items)
              if (item.planDate == row.planDate) item,
          ],
          unmet: <db.PlanUnmetMinimum>[
            for (final rowUnmet in unmet)
              if (rowUnmet.planDate == row.planDate) rowUnmet,
          ],
          catalog: catalog,
        ),
    ];
  }

  Future<void> _insertDay(DayPlan day, DateTime fetchedAt) async {
    await _database.into(_database.plans).insert(planCompanion(day, fetchedAt));
    await _database.batch((Batch batch) {
      batch.insertAll(_database.planItems, <db.PlanItemsCompanion>[
        for (final item in day.items) itemCompanion(item),
      ]);
      batch.insertAll(
        _database.planUnmetMinimums,
        <db.PlanUnmetMinimumsCompanion>[
          for (final row in day.unmetMinimums)
            unmetCompanion(day.planDate, row),
        ],
      );
    });
  }

  Future<Map<int, ({String name, String icon, bool liked})>> _catalog(
    Set<int> ids,
  ) async {
    if (ids.isEmpty) {
      return const <int, ({String name, String icon, bool liked})>{};
    }
    final lang = _locale();
    final meals = await (_database.select(
      _database.meals,
    )..where((t) => t.lang.equals(lang) & t.mealId.isIn(ids))).get();
    final tags = await (_database.select(
      _database.mealTags,
    )..where((t) => t.lang.equals(lang) & t.mealId.isIn(ids))).get();
    final prefs = await (_database.select(
      _database.localMealPrefs,
    )..where((t) => t.mealId.isIn(ids))).get();
    final liked = <int, bool>{
      for (final pref in prefs) pref.mealId: pref.stance == 'LIKE',
    };
    final byMeal = <int, List<String>>{};
    for (final tag in tags) {
      byMeal.putIfAbsent(tag.mealId, () => <String>[]).add(tag.tag);
    }
    return <int, ({String name, String icon, bool liked})>{
      for (final meal in meals)
        meal.mealId: (
          name: meal.name,
          icon: iconForOccasionTags(byMeal[meal.mealId] ?? const <String>[]),
          liked: liked[meal.mealId] ?? false,
        ),
    };
  }
}

class TodayRepository {
  TodayRepository(
    this._database,
    this._api,
    this._plans, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final db.AppDatabase _database;
  final PlanApi _api;
  final PlanRepository _plans;
  final DateTime Function() _now;
  final Map<String, Future<void>> _refreshing = <String, Future<void>>{};

  Future<void> refreshDay(DateTime date) {
    final key = isoDate(dateOnly(date));
    final current = _refreshing[key];
    if (current != null) {
      return current;
    }
    final future = _refresh(date);
    _refreshing[key] = future;
    return future.whenComplete(() {
      _refreshing.remove(key);
    });
  }

  Future<void> _refresh(DateTime date) async {
    final detail = await _api.fetchDay(date);
    final fetchedAt = _now().toUtc();
    await _database.transaction(() async {
      await (_database.delete(
        _database.mealWindows,
      )..where((t) => t.windowDate.equals(detail.date))).go();
      await _database.batch((Batch batch) {
        batch.insertAll(_database.mealWindows, <db.MealWindowsCompanion>[
          for (final window in detail.windows)
            db.MealWindowsCompanion.insert(
              windowDate: window.date,
              slot: window.slot,
              start: window.start,
              end: window.end,
            ),
        ]);
      });
      await _database
          .into(_database.daySummaries)
          .insertOnConflictUpdate(summaryCompanion(detail.summary, fetchedAt));
    });
    final plan = detail.plan;
    if (plan == null) {
      await (_database.delete(
        _database.plans,
      )..where((t) => t.planDate.equals(detail.date))).go();
      return;
    }
    await _plans.storeDay(plan);
  }

  Stream<DaySummary?> watchSummary(String date) {
    final query = _database.select(_database.daySummaries)
      ..where((t) => t.summaryDate.equals(date));
    return query.watchSingleOrNull().map(
      (db.DaySummary? row) => row == null ? null : summaryFromRow(row),
    );
  }

  Stream<List<MealWindowSpan>> watchWindows(String date) {
    final query = _database.select(_database.mealWindows)
      ..where((t) => t.windowDate.equals(date));
    return query.watch().map(
      (List<db.MealWindow> rows) => <MealWindowSpan>[
        for (final row in rows)
          MealWindowSpan(
            date: row.windowDate,
            slot: row.slot,
            start: row.start,
            end: row.end,
          ),
      ],
    );
  }
}

Stream<T> _merge<T>(List<Stream<Object?>> sources, Future<T> Function() read) {
  return Stream<Object?>.multi((MultiStreamController<Object?> listener) {
    final subscriptions = <StreamSubscription<Object?>>[
      for (final source in sources)
        source.listen((_) => listener.add(null), onError: listener.addError),
    ];
    listener.onCancel = () {
      // Drift completes cancel on a zero-length timer. Awaiting that here
      // deadlocks a frame that is disposing the subscription.
      for (final subscription in subscriptions) {
        unawaited(subscription.cancel());
      }
    };
  }).asyncMap((Object? _) => read());
}
