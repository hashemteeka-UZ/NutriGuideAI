class EnergyTarget {
  const EnergyTarget({
    required this.kcal,
    required this.bmrKcal,
    required this.tdeeKcal,
    this.targetId,
    this.proteinG,
    this.carbG,
    this.fatG,
  });

  final int kcal;
  final double bmrKcal;
  final double tdeeKcal;

  /// Server grams of the current target (the Progress macro card, #278).
  final double? proteinG;
  final double? carbG;
  final double? fatG;

  /// Changes when the server writes a new target (#275).
  final int? targetId;
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
    this.sex,
    this.latestWeightKg,
    this.targetWeightKg,
  });

  /// The goal line of the weight chart (#280).
  final double? targetWeightKg;

  final bool eligible;
  final String goalType;
  final EnergyTarget? target;
  final List<String> conditions;
  final List<String> allergenCodes;
  final bool hasDislike;

  /// MALE or FEMALE, for gendered Arabic text.
  final String? sex;

  /// The default of the weight sheet.
  final double? latestWeightKg;

  CachedUser copyWith({bool? eligible, bool? hasDislike}) {
    return CachedUser(
      eligible: eligible ?? this.eligible,
      goalType: goalType,
      conditions: conditions,
      allergenCodes: allergenCodes,
      hasDislike: hasDislike ?? this.hasDislike,
      target: target,
      sex: sex,
      latestWeightKg: latestWeightKg,
      targetWeightKg: targetWeightKg,
    );
  }
}
