import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/profile/data/profile_update_body.dart';
import 'package:nutriguide/features/profile/domain/onboarding_steps.dart';
import 'package:nutriguide/features/profile/domain/profile_draft.dart';
import 'package:nutriguide/features/profile/domain/profile_error_step.dart';

void main() {
  test('maintain sends null target and rate, and a date-only birth date', () {
    final body = profileUpdateBody(
      _draft(goal: 'MAINTAIN'),
      timezone: 'Asia/Riyadh',
    );

    expect(body['goal_type'], 'MAINTAIN');
    expect(body['target_weight_kg'], isNull);
    expect(body['weekly_rate_kg'], isNull);
    expect(body['birth_date'], '1996-04-12');
    expect(body['ingredient_prefs'], isEmpty);
    expect(body['cuisines'], isEmpty);
    expect(body['current_weight_kg'], 70);
    expect(body['timezone'], 'Asia/Riyadh');
  });

  test('insulin adds DIABETES_INSULIN and fluid answers map to water', () {
    final insulin = profileUpdateBody(
      _draft(
        goal: 'MAINTAIN',
        insulin: true,
        conditions: <String>['DIABETES_T2'],
      ),
      timezone: 'UTC',
    );
    final conditions = insulin['conditions']! as List<Map<String, Object?>>;
    expect(conditions.map((item) => item['code']), <String>[
      'DIABETES_T2',
      'DIABETES_INSULIN',
    ]);
    expect(conditions.every((item) => item['severity'] == null), isTrue);

    final unset = profileUpdateBody(
      _draft(goal: 'LOSE', doctorSetWater: false),
      timezone: 'UTC',
    );
    expect(unset['water_goal_ml'], isNull);
    expect(unset['target_weight_kg'], 65);
    expect(unset['weekly_rate_kg'], 0.5);

    final set = profileUpdateBody(
      _draft(goal: 'LOSE', doctorSetWater: true, waterGoalMl: 1500),
      timezone: 'UTC',
    );
    expect(set['water_goal_ml'], 1500);
  });

  test('TARGET_VALIDATION maps to pace and a height error maps to measure', () {
    expect(
      stepForProfileError(code: 'TARGET_VALIDATION', fields: const <String>[]),
      OnboardingStep.pace,
    );
    expect(
      stepForProfileError(
        code: 'VALIDATION_ERROR',
        fields: const <String>['height_cm'],
      ),
      OnboardingStep.measure,
    );
    expect(
      stepForProfileError(
        code: 'UNKNOWN_CODE',
        fields: fieldsFromLocs(const <List<Object>>[
          <Object>['body', 'allergens', 0, 'code'],
        ]),
      ),
      OnboardingStep.allergy,
    );
  });
}

ProfileDraft _draft({
  required String goal,
  bool insulin = false,
  List<String> conditions = const <String>[],
  bool? doctorSetWater,
  int? waterGoalMl,
}) {
  return ProfileDraft(
    sex: 'FEMALE',
    birthDate: DateTime.utc(1996, 4, 12),
    heightCm: 165,
    weightKg: 70,
    goal: goal,
    targetWeightKg: goal == 'MAINTAIN' ? null : 65,
    weeklyRateKg: goal == 'MAINTAIN' ? null : 0.5,
    activity: 'LIGHT',
    conditionCodes: conditions,
    declinedConditions: conditions.isEmpty,
    insulin: insulin,
    doctorSetWater: doctorSetWater,
    waterGoalMl: waterGoalMl,
  );
}
