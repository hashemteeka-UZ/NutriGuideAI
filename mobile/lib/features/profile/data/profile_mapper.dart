import '../../../core/api/generated/models/profile_state.dart';
import '../../../core/api/generated/models/target.dart';
import '../../../core/api/generated/models/targets_view.dart';
import '../domain/profile_result.dart';

ProfileResult mapProfileResult(ProfileState state, TargetsView targets) {
  return ProfileResult(
    eligible: state.screening.eligible,
    reasons: state.screening.reasons,
    goalType: state.profile.goalType.json ?? 'MAINTAIN',
    target: state.target == null ? null : _target(state.target!),
    water: WaterView(
      goalMl: targets.water.goalMl,
      source: targets.water.source.json ?? 'NONE',
      requiresClinician: targets.water.requiresClinician,
    ),
  );
}

DailyTarget _target(Target target) {
  return DailyTarget(
    kcal: target.kcal,
    proteinG: target.proteinG,
    carbG: target.carbG,
    fatG: target.fatG,
    fiberG: target.fiberG,
    bmrKcal: target.bmrKcal,
    tdeeKcal: target.tdeeKcal,
    floorApplied: target.wasFloorApplied,
    basedOnWeightKg: target.basedOnWeightKg,
  );
}
