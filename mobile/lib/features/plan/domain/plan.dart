class NutrientAmounts {
  const NutrientAmounts({
    this.kcal,
    this.proteinG,
    this.carbG,
    this.fatG,
    this.fiberG,
    this.saturatedFatG,
    this.sodiumMg,
    this.sugarsG,
  });

  final double? kcal;
  final double? proteinG;
  final double? carbG;
  final double? fatG;
  final double? fiberG;
  final double? saturatedFatG;
  final double? sodiumMg;
  final double? sugarsG;
}

class PlanTarget {
  const PlanTarget({
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.fiberG,
  });

  final int kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final int fiberG;
}

class PlanStatsView {
  const PlanStatsView({
    required this.solverStatus,
    required this.kcalRelaxed,
    required this.solveSeconds,
    required this.candidateMeals,
  });

  final String solverStatus;
  final bool kcalRelaxed;
  final double solveSeconds;
  final int candidateMeals;
}

class UnmetMinimum {
  const UnmetMinimum({
    required this.nutrient,
    required this.minimum,
    this.total,
  });

  final String nutrient;
  final double minimum;
  final double? total;
}

class PlanItem {
  const PlanItem({
    required this.planItemId,
    required this.planDate,
    required this.position,
    required this.slot,
    required this.mealId,
    required this.mealName,
    required this.servingsMultiplier,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.reasonCodes,
    required this.wasSwapped,
    required this.logged,
    this.iconName,
    this.liked = false,
  });

  final int planItemId;
  final String planDate;
  final int position;
  final String slot;
  final int mealId;
  final String mealName;
  final double servingsMultiplier;
  final double grams;
  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final List<String> reasonCodes;
  final bool wasSwapped;
  final bool logged;
  final String? iconName;
  final bool liked;

  PlanItem copyWith({String? mealName, String? iconName, bool? liked}) {
    return PlanItem(
      planItemId: planItemId,
      planDate: planDate,
      position: position,
      slot: slot,
      mealId: mealId,
      mealName: mealName ?? this.mealName,
      servingsMultiplier: servingsMultiplier,
      grams: grams,
      kcal: kcal,
      proteinG: proteinG,
      carbG: carbG,
      fatG: fatG,
      reasonCodes: reasonCodes,
      wasSwapped: wasSwapped,
      logged: logged,
      iconName: iconName ?? this.iconName,
      liked: liked ?? this.liked,
    );
  }
}

class DayPlan {
  const DayPlan({
    required this.planDate,
    required this.planId,
    required this.algorithmVersion,
    required this.createdAt,
    required this.target,
    required this.totals,
    required this.kcalWithin10pct,
    required this.items,
    required this.unmetMinimums,
    this.stats,
  });

  final String planDate;
  final int planId;
  final String algorithmVersion;
  final DateTime createdAt;
  final PlanTarget target;
  final NutrientAmounts totals;
  final bool kcalWithin10pct;
  final PlanStatsView? stats;
  final List<PlanItem> items;
  final List<UnmetMinimum> unmetMinimums;

  bool get hasLoggedItem => items.any((PlanItem item) => item.logged);
}

class MealWindowSpan {
  const MealWindowSpan({
    required this.date,
    required this.slot,
    required this.start,
    required this.end,
  });

  final String date;
  final String slot;
  final String start;
  final String end;
}

class DaySummary {
  const DaySummary({
    required this.date,
    required this.planItemsTotal,
    required this.planItemsConsumed,
    required this.totalMl,
    required this.requiresClinician,
    this.targetKcal,
    this.kcal,
    this.proteinG,
    this.carbG,
    this.fatG,
    this.status,
    this.goalMl,
  });

  final String date;
  final double? targetKcal;
  final double? kcal;
  final double? proteinG;
  final double? carbG;
  final double? fatG;
  final int planItemsTotal;
  final int planItemsConsumed;
  final String? status;
  final int totalMl;
  final int? goalMl;
  final bool requiresClinician;

  bool get clinicianWithoutGoal => requiresClinician && goalMl == null;
}

class DayDetail {
  const DayDetail({
    required this.date,
    required this.summary,
    required this.windows,
    this.plan,
  });

  final String date;
  final DayPlan? plan;
  final List<MealWindowSpan> windows;
  final DaySummary summary;
}

class PlanAlternative {
  const PlanAlternative({
    required this.mealId,
    required this.name,
    required this.kcal,
    required this.kcalDelta,
    required this.servingsMultiplier,
  });

  final int mealId;
  final String name;
  final double kcal;
  final double kcalDelta;
  final double servingsMultiplier;
}

/// A failure from a plan request. [network] is a connection failure.
/// [code] is null for that case.
class PlanRequestException implements Exception {
  const PlanRequestException({
    this.code,
    this.retryAfterSeconds,
    this.network = false,
  });

  final String? code;
  final int? retryAfterSeconds;
  final bool network;

  @override
  String toString() => 'PlanRequestException($code, network: $network)';
}

const slotOrder = <String>['BREAKFAST', 'LUNCH', 'SNACK', 'DINNER'];

int slotRank(String slot) {
  final index = slotOrder.indexOf(slot);
  return index < 0 ? slotOrder.length : index;
}

/// Slot order when it matches the server order. Otherwise the server order.
List<PlanItem> displayItems(List<PlanItem> items) {
  final byPosition = <PlanItem>[...items]
    ..sort((PlanItem a, PlanItem b) => a.position.compareTo(b.position));
  final bySlot = <PlanItem>[...items]
    ..sort((PlanItem a, PlanItem b) {
      final rank = slotRank(a.slot).compareTo(slotRank(b.slot));
      if (rank != 0) {
        return rank;
      }
      return a.position.compareTo(b.position);
    });
  for (var index = 0; index < byPosition.length; index++) {
    if (byPosition[index].planItemId != bySlot[index].planItemId) {
      return byPosition;
    }
  }
  return bySlot;
}
