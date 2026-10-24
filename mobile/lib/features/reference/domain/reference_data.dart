class ConditionInfo {
  const ConditionInfo({
    required this.code,
    required this.name,
    required this.isSupported,
    required this.fluidGoalRequiresClinician,
  });

  final String code;
  final String name;
  final bool isSupported;
  final bool fluidGoalRequiresClinician;
}

class AllergenInfo {
  const AllergenInfo({required this.code, required this.name});

  final String code;
  final String name;
}

class ReferenceData {
  const ReferenceData({
    required this.conditions,
    required this.allergens,
    required this.activityLevels,
    required this.goals,
    required this.sexes,
  });

  final List<ConditionInfo> conditions;
  final List<AllergenInfo> allergens;
  final List<String> activityLevels;
  final List<String> goals;
  final List<String> sexes;

  List<ConditionInfo> get supportedConditions => [
    for (final condition in conditions)
      if (condition.isSupported) condition,
  ];
}

abstract interface class ReferenceRepository {
  Future<ReferenceData> load({required String locale});
}

Set<String> clinicianFluidCodes(ReferenceData? data) {
  if (data == null) {
    return const <String>{'HEART_DISEASE'};
  }
  return <String>{
    for (final condition in data.conditions)
      if (condition.fluidGoalRequiresClinician) condition.code,
  };
}
