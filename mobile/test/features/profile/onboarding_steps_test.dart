import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/profile/domain/onboarding_steps.dart';
import 'package:nutriguide/features/profile/domain/profile_draft.dart';

void main() {
  const base = <OnboardingStep>[
    OnboardingStep.about,
    OnboardingStep.measure,
    OnboardingStep.goal,
    OnboardingStep.activity,
    OnboardingStep.care,
    OnboardingStep.allergy,
    OnboardingStep.rhythm,
  ];

  test('maintain, lose, and gain', () {
    expect(onboardingSteps(const ProfileDraft()), base);
    expect(onboardingSteps(const ProfileDraft(goal: 'MAINTAIN')), base);
    expect(
      onboardingSteps(const ProfileDraft(goal: 'LOSE')),
      _insert(base, OnboardingStep.goal, OnboardingStep.pace),
    );
    expect(
      onboardingSteps(const ProfileDraft(goal: 'GAIN')),
      _insert(base, OnboardingStep.goal, OnboardingStep.pace),
    );
  });

  test('diabetes adds safety and heart disease adds fluid', () {
    final diabetes = onboardingSteps(
      const ProfileDraft(conditionCodes: <String>['DIABETES_T2']),
    );
    expect(
      diabetes,
      _insert(base, OnboardingStep.allergy, OnboardingStep.safety),
    );

    final heart = onboardingSteps(
      const ProfileDraft(conditionCodes: <String>['HEART_DISEASE']),
    );
    expect(heart, <OnboardingStep>[...base, OnboardingStep.fluid]);

    final both = onboardingSteps(
      const ProfileDraft(
        conditionCodes: <String>['DIABETES_T2', 'HEART_DISEASE'],
      ),
    );
    expect(both.contains(OnboardingStep.safety), isTrue);
    expect(both.contains(OnboardingStep.fluid), isTrue);
    expect(
      both.indexOf(OnboardingStep.safety),
      lessThan(both.indexOf(OnboardingStep.rhythm)),
    );
    expect(both.indexOf(OnboardingStep.fluid), both.length - 1);
  });

  test('changing the goal removes pace and lands back on goal', () {
    const lose = ProfileDraft(goal: 'LOSE');
    final before = onboardingSteps(lose);
    final paceIndex = before.indexOf(OnboardingStep.pace);
    final after = onboardingSteps(const ProfileDraft(goal: 'MAINTAIN'));

    expect(before.contains(OnboardingStep.pace), isTrue);
    expect(after.contains(OnboardingStep.pace), isFalse);
    expect(
      resolveStepIndex(before, paceIndex, after),
      after.indexOf(OnboardingStep.goal),
    );
  });

  test('a clinician fluid flag on the selected code adds fluid', () {
    final steps = onboardingSteps(
      const ProfileDraft(conditionCodes: <String>['OTHER']),
      clinicianFluidCodes: const <String>{'OTHER'},
    );

    expect(steps.last, OnboardingStep.fluid);
  });
}

List<OnboardingStep> _insert(
  List<OnboardingStep> steps,
  OnboardingStep after,
  OnboardingStep extra,
) {
  final copy = <OnboardingStep>[...steps];
  copy.insert(copy.indexOf(after) + 1, extra);
  return copy;
}
