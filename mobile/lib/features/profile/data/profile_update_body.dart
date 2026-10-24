import '../domain/clock_time.dart';
import '../domain/profile_draft.dart';

Map<String, Object?> profileUpdateBody(
  ProfileDraft draft, {
  required String timezone,
}) {
  final birth = draft.birthDate;
  if (birth == null ||
      draft.sex == null ||
      draft.goal == null ||
      draft.activity == null) {
    throw StateError('Profile draft is incomplete');
  }
  final maintain = draft.goal == 'MAINTAIN';
  return <String, Object?>{
    'sex': draft.sex,
    'birth_date': formatIsoDate(birth),
    'height_cm': draft.heightCm,
    'current_weight_kg': draft.weightKg,
    'activity_level': draft.activity,
    'goal_type': draft.goal,
    'target_weight_kg': maintain ? null : draft.targetWeightKg,
    'weekly_rate_kg': maintain ? null : draft.weeklyRateKg,
    'conditions': _conditions(draft),
    'allergens': <Map<String, Object?>>[
      for (final entry in draft.allergens.entries)
        <String, Object?>{'code': entry.key, 'severity': entry.value},
    ],
    'ingredient_prefs': <Map<String, Object?>>[],
    'cuisines': <String>[],
    'wake_time': formatClock(draft.wakeMinutes),
    'sleep_time': formatClock(draft.sleepMinutes),
    'water_goal_ml': draft.doctorSetWater == true ? draft.waterGoalMl : null,
    'timezone': timezone,
  };
}

List<Map<String, Object?>> _conditions(ProfileDraft draft) {
  final codes = <String>[...draft.conditionCodes];
  if (draft.insulin == true && !codes.contains('DIABETES_INSULIN')) {
    codes.add('DIABETES_INSULIN');
  }
  return <Map<String, Object?>>[
    for (final code in codes) <String, Object?>{'code': code, 'severity': null},
  ];
}
