class EnergyTarget {
  const EnergyTarget({
    required this.kcal,
    required this.bmrKcal,
    required this.tdeeKcal,
  });

  final int kcal;
  final double bmrKcal;
  final double tdeeKcal;
}

/// Profile facts kept in memory. Conditions are not stored in a table.
class CachedUser {
  const CachedUser({
    required this.eligible,
    required this.goalType,
    required this.conditions,
    required this.allergenCodes,
    required this.hasDislike,
    this.target,
  });

  final bool eligible;
  final String goalType;
  final EnergyTarget? target;
  final List<String> conditions;
  final List<String> allergenCodes;
  final bool hasDislike;

  CachedUser copyWith({bool? eligible, bool? hasDislike}) {
    return CachedUser(
      eligible: eligible ?? this.eligible,
      goalType: goalType,
      conditions: conditions,
      allergenCodes: allergenCodes,
      hasDislike: hasDislike ?? this.hasDislike,
      target: target,
    );
  }
}
