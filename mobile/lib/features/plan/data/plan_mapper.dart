import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/api/generated/models/alternative.dart';
import '../../../core/api/generated/models/day_adherence_out.dart';
import '../../../core/api/generated/models/day_plan_out.dart';
import '../../../core/api/generated/models/day_view.dart';
import '../../../core/api/generated/models/meal_window.dart' as api;
import '../../../core/api/generated/models/nutrient_totals.dart';
import '../../../core/api/generated/models/plan_item_out.dart';
import '../../../core/api/generated/models/plan_stats.dart';
import '../../../core/api/generated/models/plan_target_out.dart';
import '../../../core/api/generated/models/shopping_item.dart' as api_shop;
import '../../../core/api/generated/models/unmet_minimum_out.dart';
import '../../../core/api/generated/models/water_day.dart';
import '../../../core/db/app_database.dart' as db;
import '../../shopping/domain/shopping.dart';
import '../domain/plan.dart';
import '../domain/plan_dates.dart';

double _d(num value) => value.toDouble();

double? _dn(num? value) => value?.toDouble();

String encodeReasons(List<String> codes) => jsonEncode(codes);

List<String> decodeReasons(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <String>[];
    }
    return <String>[
      for (final Object? item in decoded)
        if (item is String) item,
    ];
  } on FormatException {
    return const <String>[];
  }
}

DayPlan dayPlanFromApi(DayPlanOut plan) {
  final date = isoDate(plan.date);
  return DayPlan(
    planDate: date,
    planId: plan.planId,
    algorithmVersion: plan.algorithmVersion,
    createdAt: plan.createdAt.toUtc(),
    target: _target(plan.target),
    totals: _totals(plan.totals),
    kcalWithin10pct: plan.kcalWithin10pct,
    stats: plan.stats == null ? null : _stats(plan.stats!),
    items: <PlanItem>[
      for (var index = 0; index < plan.items.length; index++)
        planItemFromApi(plan.items[index], planDate: date, position: index),
    ],
    unmetMinimums: <UnmetMinimum>[
      for (final row in plan.unmetMinimums) _unmet(row),
    ],
  );
}

PlanItem planItemFromApi(
  PlanItemOut item, {
  required String planDate,
  required int position,
}) {
  return PlanItem(
    planItemId: item.planItemId,
    planDate: planDate,
    position: position,
    slot: item.slot.json ?? '',
    mealId: item.meal.mealId,
    mealName: item.meal.name,
    servingsMultiplier: _d(item.servingsMultiplier),
    grams: _d(item.grams),
    kcal: _d(item.kcal),
    proteinG: _d(item.proteinG),
    carbG: _d(item.carbG),
    fatG: _d(item.fatG),
    reasonCodes: item.reasonCodes,
    wasSwapped: item.wasSwapped,
    logged: item.logged,
  );
}

PlanAlternative alternativeFromApi(Alternative alternative) {
  return PlanAlternative(
    mealId: alternative.meal.mealId,
    name: alternative.meal.name,
    kcal: _d(alternative.kcal),
    kcalDelta: _d(alternative.kcalDelta),
    servingsMultiplier: _d(alternative.servingsMultiplier),
  );
}

DayDetail dayDetailFromApi(DayView view) {
  final date = isoDate(view.date);
  return DayDetail(
    date: date,
    plan: view.plan == null ? null : dayPlanFromApi(view.plan!),
    windows: <MealWindowSpan>[
      for (final window in view.mealWindows) _window(date, window),
    ],
    summary: _summary(date, view.adherence, view.water),
  );
}

ShoppingRow shoppingRowFromApi(api_shop.ShoppingItem item) {
  return ShoppingRow(
    ingredientId: item.ingredientId,
    name: item.name,
    grams: _d(item.grams),
    meals: item.meals,
    checked: false,
  );
}

PlanTarget _target(PlanTargetOut target) {
  return PlanTarget(
    kcal: target.kcal,
    proteinG: _d(target.proteinG),
    carbG: _d(target.carbG),
    fatG: _d(target.fatG),
    fiberG: target.fiberG,
  );
}

NutrientAmounts _totals(NutrientTotals totals) {
  return NutrientAmounts(
    kcal: _dn(totals.kcal),
    proteinG: _dn(totals.proteinG),
    carbG: _dn(totals.carbG),
    fatG: _dn(totals.fatG),
    fiberG: _dn(totals.fiberG),
    saturatedFatG: _dn(totals.saturatedFatG),
    sodiumMg: _dn(totals.sodiumMg),
    sugarsG: _dn(totals.sugarsG),
  );
}

PlanStatsView _stats(PlanStats stats) {
  return PlanStatsView(
    solverStatus: stats.solverStatus,
    kcalRelaxed: stats.kcalRelaxed,
    solveSeconds: _d(stats.solveSeconds),
    candidateMeals: stats.candidateMeals,
  );
}

UnmetMinimum _unmet(UnmetMinimumOut row) {
  return UnmetMinimum(
    nutrient: row.nutrient,
    minimum: _d(row.minimum),
    total: _dn(row.total),
  );
}

MealWindowSpan _window(String date, api.MealWindow window) {
  return MealWindowSpan(
    date: date,
    slot: window.slot.json ?? '',
    start: window.start,
    end: window.end,
  );
}

DaySummary _summary(String date, DayAdherenceOut adherence, WaterDay water) {
  return DaySummary(
    date: date,
    targetKcal: _dn(adherence.targetKcal),
    kcal: _dn(adherence.totals.kcal),
    proteinG: _dn(adherence.totals.proteinG),
    carbG: _dn(adherence.totals.carbG),
    fatG: _dn(adherence.totals.fatG),
    planItemsTotal: adherence.planItemsTotal,
    planItemsConsumed: adherence.planItemsConsumed,
    status: adherence.status?.json,
    totalMl: water.totalMl,
    goalMl: water.goal.goalMl,
    requiresClinician: water.goal.requiresClinician,
  );
}

db.PlansCompanion planCompanion(DayPlan day, DateTime fetchedAt) {
  final stats = day.stats;
  return db.PlansCompanion.insert(
    planDate: day.planDate,
    planId: day.planId,
    algorithmVersion: day.algorithmVersion,
    createdAt: day.createdAt.toUtc(),
    kcal: day.target.kcal,
    proteinG: day.target.proteinG,
    carbG: day.target.carbG,
    fatG: day.target.fatG,
    fiberG: day.target.fiberG,
    totalsKcal: Value(day.totals.kcal),
    totalsProteinG: Value(day.totals.proteinG),
    totalsCarbG: Value(day.totals.carbG),
    totalsFatG: Value(day.totals.fatG),
    totalsFiberG: Value(day.totals.fiberG),
    totalsSaturatedFatG: Value(day.totals.saturatedFatG),
    totalsSodiumMg: Value(day.totals.sodiumMg),
    totalsSugarsG: Value(day.totals.sugarsG),
    kcalWithin10pct: day.kcalWithin10pct,
    solverStatus: Value(stats?.solverStatus),
    kcalRelaxed: Value(stats?.kcalRelaxed),
    solveSeconds: Value(stats?.solveSeconds),
    candidateMeals: Value(stats?.candidateMeals),
    fetchedAt: fetchedAt.toUtc(),
  );
}

db.PlanItemsCompanion itemCompanion(PlanItem item) {
  return db.PlanItemsCompanion.insert(
    planItemId: Value(item.planItemId),
    planDate: item.planDate,
    position: item.position,
    slot: item.slot,
    mealId: item.mealId,
    mealName: item.mealName,
    servingsMultiplier: item.servingsMultiplier,
    grams: item.grams,
    kcal: item.kcal,
    proteinG: item.proteinG,
    carbG: item.carbG,
    fatG: item.fatG,
    reasonCodes: encodeReasons(item.reasonCodes),
    wasSwapped: item.wasSwapped,
    logged: item.logged,
  );
}

db.PlanUnmetMinimumsCompanion unmetCompanion(String date, UnmetMinimum row) {
  return db.PlanUnmetMinimumsCompanion.insert(
    planDate: date,
    nutrient: row.nutrient,
    minimum: row.minimum,
    total: Value(row.total),
  );
}

DayPlan dayPlanFromRows({
  required db.Plan row,
  required List<db.PlanItem> items,
  required List<db.PlanUnmetMinimum> unmet,
  Map<int, ({String name, String icon, bool liked})> catalog =
      const <int, ({String name, String icon, bool liked})>{},
}) {
  final stats = row.solverStatus == null
      ? null
      : PlanStatsView(
          solverStatus: row.solverStatus!,
          kcalRelaxed: row.kcalRelaxed ?? false,
          solveSeconds: row.solveSeconds ?? 0,
          candidateMeals: row.candidateMeals ?? 0,
        );
  final sorted = <db.PlanItem>[...items]
    ..sort((db.PlanItem a, db.PlanItem b) => a.position.compareTo(b.position));
  return DayPlan(
    planDate: row.planDate,
    planId: row.planId,
    algorithmVersion: row.algorithmVersion,
    createdAt: row.createdAt,
    target: PlanTarget(
      kcal: row.kcal,
      proteinG: row.proteinG,
      carbG: row.carbG,
      fatG: row.fatG,
      fiberG: row.fiberG,
    ),
    totals: NutrientAmounts(
      kcal: row.totalsKcal,
      proteinG: row.totalsProteinG,
      carbG: row.totalsCarbG,
      fatG: row.totalsFatG,
      fiberG: row.totalsFiberG,
      saturatedFatG: row.totalsSaturatedFatG,
      sodiumMg: row.totalsSodiumMg,
      sugarsG: row.totalsSugarsG,
    ),
    kcalWithin10pct: row.kcalWithin10pct,
    stats: stats,
    items: <PlanItem>[
      for (final item in sorted) _itemFromRow(item, catalog[item.mealId]),
    ],
    unmetMinimums: <UnmetMinimum>[
      for (final row in unmet)
        UnmetMinimum(
          nutrient: row.nutrient,
          minimum: row.minimum,
          total: row.total,
        ),
    ],
  );
}

PlanItem _itemFromRow(
  db.PlanItem row,
  ({String name, String icon, bool liked})? catalog,
) {
  return PlanItem(
    planItemId: row.planItemId,
    planDate: row.planDate,
    position: row.position,
    slot: row.slot,
    mealId: row.mealId,
    mealName: catalog?.name ?? row.mealName,
    servingsMultiplier: row.servingsMultiplier,
    grams: row.grams,
    kcal: row.kcal,
    proteinG: row.proteinG,
    carbG: row.carbG,
    fatG: row.fatG,
    reasonCodes: decodeReasons(row.reasonCodes),
    wasSwapped: row.wasSwapped,
    logged: row.logged,
    iconName: catalog?.icon,
    liked: catalog?.liked ?? false,
  );
}

DaySummary summaryFromRow(db.DaySummary row) {
  return DaySummary(
    date: row.summaryDate,
    targetKcal: row.targetKcal,
    kcal: row.kcal,
    proteinG: row.proteinG,
    carbG: row.carbG,
    fatG: row.fatG,
    planItemsTotal: row.planItemsTotal,
    planItemsConsumed: row.planItemsConsumed,
    status: row.status,
    totalMl: row.totalMl,
    goalMl: row.goalMl,
    requiresClinician: row.requiresClinician,
  );
}

db.DaySummariesCompanion summaryCompanion(
  DaySummary summary,
  DateTime fetchedAt,
) {
  return db.DaySummariesCompanion.insert(
    summaryDate: summary.date,
    targetKcal: Value(summary.targetKcal),
    kcal: Value(summary.kcal),
    proteinG: Value(summary.proteinG),
    carbG: Value(summary.carbG),
    fatG: Value(summary.fatG),
    planItemsTotal: summary.planItemsTotal,
    planItemsConsumed: summary.planItemsConsumed,
    status: Value(summary.status),
    totalMl: summary.totalMl,
    goalMl: Value(summary.goalMl),
    requiresClinician: summary.requiresClinician,
    fetchedAt: fetchedAt.toUtc(),
  );
}
