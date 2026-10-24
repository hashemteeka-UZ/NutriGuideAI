class DailyTarget {
  const DailyTarget({
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.fiberG,
    required this.bmrKcal,
    required this.tdeeKcal,
    required this.floorApplied,
    required this.basedOnWeightKg,
  });

  final int kcal;
  final num proteinG;
  final num carbG;
  final num fatG;
  final int fiberG;
  final num bmrKcal;
  final num tdeeKcal;
  final bool floorApplied;
  final num basedOnWeightKg;
}

class WaterView {
  const WaterView({
    required this.goalMl,
    required this.source,
    required this.requiresClinician,
  });

  final int? goalMl;
  final String source;
  final bool requiresClinician;

  bool get clinicianWithoutGoal => requiresClinician && goalMl == null;
}

class ProfileResult {
  const ProfileResult({
    required this.eligible,
    required this.reasons,
    required this.goalType,
    required this.target,
    required this.water,
  });

  final bool eligible;
  final List<String> reasons;
  final String goalType;
  final DailyTarget? target;
  final WaterView water;

  bool get showPersonalPlan => eligible && target != null;
}

enum CalcLineKind { resting, activity, adjustment, floor, daily }

class CalcLine {
  const CalcLine(this.kind, this.primary, {this.secondary});

  final CalcLineKind kind;
  final num primary;

  /// Activity factor, or the weight the daily target is based on.
  final num? secondary;
}

List<CalcLine> calculationLines({
  required DailyTarget target,
  required String goalType,
}) {
  final lines = <CalcLine>[
    CalcLine(CalcLineKind.resting, target.bmrKcal),
    CalcLine(
      CalcLineKind.activity,
      target.tdeeKcal,
      secondary: target.bmrKcal == 0 ? null : target.tdeeKcal / target.bmrKcal,
    ),
  ];
  if (goalType != 'MAINTAIN') {
    lines.add(
      CalcLine(CalcLineKind.adjustment, (target.kcal - target.tdeeKcal).abs()),
    );
  }
  if (target.floorApplied) {
    lines.add(CalcLine(CalcLineKind.floor, target.kcal));
  }
  lines.add(
    CalcLine(
      CalcLineKind.daily,
      target.kcal,
      secondary: target.basedOnWeightKg,
    ),
  );
  return lines;
}
