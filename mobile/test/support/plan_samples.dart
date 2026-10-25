import 'package:nutriguide/features/plan/domain/plan.dart';

PlanItem sampleItem({
  int planItemId = 1,
  String planDate = '2026-10-24',
  int position = 0,
  String slot = 'BREAKFAST',
  int mealId = 10,
  String mealName = 'فول',
  double kcal = 400,
  bool logged = false,
  List<String> reasonCodes = const <String>['HIGH_PROTEIN'],
}) {
  return PlanItem(
    planItemId: planItemId,
    planDate: planDate,
    position: position,
    slot: slot,
    mealId: mealId,
    mealName: mealName,
    servingsMultiplier: 1,
    grams: 250,
    kcal: kcal,
    proteinG: 20,
    carbG: 30,
    fatG: 10,
    reasonCodes: reasonCodes,
    wasSwapped: false,
    logged: logged,
  );
}

DayPlan sampleDay({
  required String planDate,
  int planId = 1,
  int kcal = 1800,
  double? totalsKcal = 1750,
  List<PlanItem>? items,
  PlanStatsView? stats,
  List<UnmetMinimum> unmet = const <UnmetMinimum>[],
  bool within = true,
}) {
  return DayPlan(
    planDate: planDate,
    planId: planId,
    algorithmVersion: 'cp-sat',
    createdAt: DateTime.utc(2026, 10, 24),
    target: PlanTarget(
      kcal: kcal,
      proteinG: 90,
      carbG: 180,
      fatG: 60,
      fiberG: 30,
    ),
    totals: NutrientAmounts(kcal: totalsKcal),
    kcalWithin10pct: within,
    stats: stats,
    items: items ?? <PlanItem>[sampleItem(planDate: planDate)],
    unmetMinimums: unmet,
  );
}

PlanStatsView sampleStats({int candidates = 40, String status = 'OPTIMAL'}) {
  return PlanStatsView(
    solverStatus: status,
    kcalRelaxed: false,
    solveSeconds: 1.2,
    candidateMeals: candidates,
  );
}
