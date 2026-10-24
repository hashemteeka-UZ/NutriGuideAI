import 'onboarding_steps.dart';

const _fieldSteps = <String, OnboardingStep>{
  'sex': OnboardingStep.about,
  'birth_date': OnboardingStep.about,
  'height_cm': OnboardingStep.measure,
  'current_weight_kg': OnboardingStep.measure,
  'goal_type': OnboardingStep.goal,
  'target_weight_kg': OnboardingStep.pace,
  'weekly_rate_kg': OnboardingStep.pace,
  'activity_level': OnboardingStep.activity,
  'conditions': OnboardingStep.care,
  'allergens': OnboardingStep.allergy,
  'wake_time': OnboardingStep.rhythm,
  'sleep_time': OnboardingStep.rhythm,
  'water_goal_ml': OnboardingStep.fluid,
};

OnboardingStep? stepForProfileError({
  required String code,
  required List<String> fields,
}) {
  if (code == 'TARGET_VALIDATION') {
    return _firstKnown(fields) ?? OnboardingStep.pace;
  }
  if (code == 'VALIDATION_ERROR' || code == 'UNKNOWN_CODE') {
    return _firstKnown(fields);
  }
  return null;
}

OnboardingStep? _firstKnown(List<String> fields) {
  for (final field in fields) {
    final step = _fieldSteps[field];
    if (step != null) {
      return step;
    }
  }
  return null;
}

List<String> fieldsFromLocs(Iterable<List<Object>> locs) {
  final fields = <String>[];
  for (final loc in locs) {
    String? known;
    String? fallback;
    for (final part in loc) {
      if (part is! String || part == 'body') {
        continue;
      }
      fallback ??= part;
      if (_fieldSteps.containsKey(part)) {
        known = part;
        break;
      }
    }
    final field = known ?? fallback;
    if (field != null) {
      fields.add(field);
    }
  }
  return fields;
}
