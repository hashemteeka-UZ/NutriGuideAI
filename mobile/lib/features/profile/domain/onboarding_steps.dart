import 'pace_rules.dart';
import 'profile_draft.dart';

enum OnboardingStep {
  about,
  measure,
  goal,
  pace,
  activity,
  care,
  allergy,
  safety,
  rhythm,
  fluid,
}

const defaultClinicianFluidCodes = <String>{'HEART_DISEASE'};

List<OnboardingStep> onboardingSteps(
  ProfileDraft draft, {
  Set<String> clinicianFluidCodes = defaultClinicianFluidCodes,
}) {
  final steps = <OnboardingStep>[
    OnboardingStep.about,
    OnboardingStep.measure,
    OnboardingStep.goal,
  ];
  if (paceApplies(draft.goal)) {
    steps.add(OnboardingStep.pace);
  }
  steps.add(OnboardingStep.activity);
  steps.add(OnboardingStep.care);
  steps.add(OnboardingStep.allergy);
  if (draft.hasDiabetes) {
    steps.add(OnboardingStep.safety);
  }
  steps.add(OnboardingStep.rhythm);
  final needsFluid = draft.conditionCodes.any(clinicianFluidCodes.contains);
  if (needsFluid) {
    steps.add(OnboardingStep.fluid);
  }
  return steps;
}

int resolveStepIndex(
  List<OnboardingStep> previous,
  int index,
  List<OnboardingStep> next,
) {
  if (next.isEmpty) {
    return 0;
  }
  if (previous.isEmpty) {
    return 0;
  }
  final safeIndex = index.clamp(0, previous.length - 1);
  final current = previous[safeIndex];
  final kept = next.indexOf(current);
  if (kept >= 0) {
    return kept;
  }
  for (var i = safeIndex - 1; i >= 0; i--) {
    final found = next.indexOf(previous[i]);
    if (found >= 0) {
      return found;
    }
  }
  return 0;
}

bool stepIsValid(OnboardingStep step, ProfileDraft draft) {
  switch (step) {
    case OnboardingStep.about:
      return draft.sex != null && draft.birthDate != null;
    case OnboardingStep.measure:
      return _inRange(draft.heightCm, 100, 250) &&
          _inRange(draft.weightKg, 20, 400);
    case OnboardingStep.goal:
      if (draft.goal == 'MAINTAIN') {
        return true;
      }
      if (draft.goal == 'GAIN') {
        return gainIsOffered(weightKg: draft.weightKg);
      }
      if (draft.goal == 'LOSE') {
        return loseIsOffered(
          heightCm: draft.heightCm,
          weightKg: draft.weightKg,
        );
      }
      return false;
    case OnboardingStep.pace:
      final target = draft.targetWeightKg;
      final rate = draft.weeklyRateKg;
      if (target == null || rate == null || !paceApplies(draft.goal)) {
        return false;
      }
      final bounds = targetWeightBounds(
        goal: draft.goal,
        heightCm: draft.heightCm,
        weightKg: draft.weightKg,
      );
      if (bounds == null || !bounds.contains(target)) {
        return false;
      }
      return rateIsAllowed(
        goal: draft.goal,
        weightKg: draft.weightKg,
        rateKg: rate,
      );
    case OnboardingStep.activity:
      return draft.activity != null;
    case OnboardingStep.care:
      return draft.declinedConditions || draft.conditionCodes.isNotEmpty;
    case OnboardingStep.allergy:
      return true;
    case OnboardingStep.safety:
      return draft.insulin != null;
    case OnboardingStep.rhythm:
      return draft.wakeMinutes != draft.sleepMinutes;
    case OnboardingStep.fluid:
      if (draft.doctorSetWater == false) {
        return true;
      }
      final ml = draft.waterGoalMl;
      return draft.doctorSetWater == true &&
          ml != null &&
          ml >= 500 &&
          ml <= 5000;
  }
}

bool _inRange(double value, double min, double max) {
  return value + 1e-9 >= min && value <= max + 1e-9;
}
