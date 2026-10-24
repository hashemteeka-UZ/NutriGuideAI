import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/network/app_failure.dart';
import '../../auth/data/auth_repository_impl.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../../reference/data/reference_repository.dart';
import '../../reference/domain/reference_data.dart';
import '../data/device_timezone.dart';
import '../data/profile_repository.dart';
import '../domain/onboarding_steps.dart';
import '../domain/pace_rules.dart';
import '../domain/profile_draft.dart';
import '../domain/profile_error_step.dart';
import '../domain/profile_result.dart';

final onboardingNowProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

enum OnboardingPhase { checking, ready, saving, result }

class OnboardingState {
  const OnboardingState({
    this.phase = OnboardingPhase.checking,
    this.draft = const ProfileDraft(),
    this.stepIndex = 0,
    this.forward = true,
    this.reference,
    this.loadError,
    this.result,
    this.timezoneFellBack = false,
    this.fieldError,
    this.actionError,
  });

  final OnboardingPhase phase;
  final ProfileDraft draft;
  final int stepIndex;
  final bool forward;
  final ReferenceData? reference;
  final Object? loadError;
  final ProfileResult? result;
  final bool timezoneFellBack;
  final AppFailure? fieldError;
  final AppFailure? actionError;

  List<OnboardingStep> get steps => onboardingSteps(
    draft,
    clinicianFluidCodes: clinicianFluidCodes(reference),
  );

  OnboardingStep? get step {
    final list = steps;
    if (stepIndex < 0 || stepIndex >= list.length) {
      return null;
    }
    return list[stepIndex];
  }

  OnboardingState copyWith({
    OnboardingPhase? phase,
    ProfileDraft? draft,
    int? stepIndex,
    bool? forward,
    Object? reference = _keep,
    Object? loadError = _keep,
    Object? result = _keep,
    bool? timezoneFellBack,
    Object? fieldError = _keep,
    Object? actionError = _keep,
  }) {
    return OnboardingState(
      phase: phase ?? this.phase,
      draft: draft ?? this.draft,
      stepIndex: stepIndex ?? this.stepIndex,
      forward: forward ?? this.forward,
      reference: reference == _keep
          ? this.reference
          : reference as ReferenceData?,
      loadError: loadError == _keep ? this.loadError : loadError,
      result: result == _keep ? this.result : result as ProfileResult?,
      timezoneFellBack: timezoneFellBack ?? this.timezoneFellBack,
      fieldError: fieldError == _keep
          ? this.fieldError
          : fieldError as AppFailure?,
      actionError: actionError == _keep
          ? this.actionError
          : actionError as AppFailure?,
    );
  }
}

const _keep = Object();

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

class OnboardingController extends Notifier<OnboardingState> {
  var _started = false;

  @override
  OnboardingState build() {
    ref.listen(sessionControllerProvider, (previous, next) {
      if (next is! SignedIn) {
        _reset();
        return;
      }
      final previousId = previous is SignedIn ? previous.account?.userId : null;
      final nextId = next.account?.userId;
      if (previousId != null && nextId != null && previousId != nextId) {
        _reset();
      }
    });
    ref.listen(localeProvider, (previous, next) {
      if (previous == null || previous.languageCode == next.languageCode) {
        return;
      }
      if (_started && state.reference != null) {
        unawaited(reloadReference());
      }
    });
    return const OnboardingState();
  }

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    state = state.copyWith(phase: OnboardingPhase.checking, loadError: null);
    final redirected = await _redirectIfProfileExists();
    if (!ref.mounted || redirected) {
      return;
    }
    await reloadReference();
  }

  Future<void> reloadReference() async {
    try {
      final locale = ref.read(localeProvider).languageCode;
      final data = await ref
          .read(referenceRepositoryProvider)
          .load(locale: locale);
      if (!ref.mounted) {
        return;
      }
      final today = ref.read(onboardingNowProvider)();
      final birth = state.draft.birthDate ?? defaultBirthDate(today);
      final phase = state.phase == OnboardingPhase.checking
          ? OnboardingPhase.ready
          : state.phase;
      state = state.copyWith(
        phase: phase,
        reference: data,
        loadError: null,
        draft: state.draft.copyWith(birthDate: birth),
      );
    } on Object catch (error) {
      if (!ref.mounted || state.reference != null) {
        return;
      }
      state = state.copyWith(phase: OnboardingPhase.ready, loadError: error);
    }
  }

  void selectSex(String sex) {
    _edit(state.draft.copyWith(sex: sex));
  }

  void setBirthDate(DateTime date) {
    final today = ref.read(onboardingNowProvider)();
    final next = clampBirthDate(date, today);
    final current = state.draft.birthDate;
    if (current != null &&
        current.year == next.year &&
        current.month == next.month &&
        current.day == next.day) {
      return;
    }
    _edit(state.draft.copyWith(birthDate: next));
  }

  void setHeight(double heightCm) {
    if ((state.draft.heightCm - heightCm).abs() < 1e-9) {
      return;
    }
    _edit(_reconcileGoal(state.draft.copyWith(heightCm: heightCm)));
  }

  void setWeight(double weightKg) {
    if ((state.draft.weightKg - weightKg).abs() < 1e-9) {
      return;
    }
    _edit(_reconcileGoal(state.draft.copyWith(weightKg: weightKg)));
  }

  void setGoal(String goal) {
    final draft = state.draft;
    if (goal == 'LOSE' &&
        !loseIsOffered(heightCm: draft.heightCm, weightKg: draft.weightKg)) {
      return;
    }
    if (goal == 'GAIN' && !gainIsOffered(weightKg: draft.weightKg)) {
      return;
    }
    if (goal == 'MAINTAIN') {
      _edit(
        draft.copyWith(goal: goal, targetWeightKg: null, weeklyRateKg: null),
      );
      return;
    }
    _edit(
      draft.copyWith(
        goal: goal,
        targetWeightKg: defaultTargetKg(
          goal: goal,
          heightCm: draft.heightCm,
          weightKg: draft.weightKg,
        ),
        weeklyRateKg: defaultRateKg(goal: goal, weightKg: draft.weightKg),
      ),
    );
  }

  void setTargetWeight(double kg) {
    final current = state.draft.targetWeightKg;
    if (current != null && (current - kg).abs() < 1e-9) {
      return;
    }
    _edit(state.draft.copyWith(targetWeightKg: kg));
  }

  void setRate(double rateKg) {
    if (!rateIsAllowed(
      goal: state.draft.goal,
      weightKg: state.draft.weightKg,
      rateKg: rateKg,
    )) {
      return;
    }
    _edit(state.draft.copyWith(weeklyRateKg: rateKg));
  }

  void setActivity(String activity) {
    _edit(state.draft.copyWith(activity: activity));
  }

  void toggleCondition(String code) {
    final next = <String>[...state.draft.conditionCodes];
    if (next.contains(code)) {
      next.remove(code);
    } else {
      next.add(code);
    }
    _edit(_clearHiddenAnswers(state.draft, next, declined: false));
  }

  void declineConditions() {
    _edit(_clearHiddenAnswers(state.draft, const <String>[], declined: true));
  }

  void cycleAllergen(String code) {
    final next = Map<String, String>.of(state.draft.allergens);
    final current = next[code];
    if (current == null) {
      next[code] = 'AVOID';
    } else if (current == 'AVOID') {
      next[code] = 'SEVERE';
    } else {
      next.remove(code);
    }
    _edit(state.draft.copyWith(allergens: next));
  }

  void setInsulin(bool usesInsulin) {
    _edit(state.draft.copyWith(insulin: usesInsulin));
  }

  void shiftWake(int minutes) {
    _edit(
      state.draft.copyWith(
        wakeMinutes: _shift(state.draft.wakeMinutes, minutes),
      ),
    );
  }

  void shiftSleep(int minutes) {
    _edit(
      state.draft.copyWith(
        sleepMinutes: _shift(state.draft.sleepMinutes, minutes),
      ),
    );
  }

  void setDoctorWater(bool doctorSet) {
    _edit(
      state.draft.copyWith(
        doctorSetWater: doctorSet,
        waterGoalMl: doctorSet ? state.draft.waterGoalMl : null,
      ),
    );
  }

  void setWaterGoal(int? ml) {
    _edit(state.draft.copyWith(doctorSetWater: true, waterGoalMl: ml));
  }

  void next({required bool reduceMotion}) {
    final steps = state.steps;
    final step = state.step;
    if (step == null || !stepIsValid(step, state.draft)) {
      return;
    }
    if (state.stepIndex >= steps.length - 1) {
      unawaited(submit(reduceMotion: reduceMotion));
      return;
    }
    state = state.copyWith(
      draft: state.draft,
      stepIndex: state.stepIndex + 1,
      forward: true,
      fieldError: null,
      actionError: null,
    );
  }

  void back() {
    if (state.phase == OnboardingPhase.result) {
      state = state.copyWith(phase: OnboardingPhase.ready, forward: false);
      return;
    }
    if (state.stepIndex == 0) {
      return;
    }
    state = state.copyWith(
      stepIndex: state.stepIndex - 1,
      forward: false,
      fieldError: null,
      actionError: null,
    );
  }

  Future<void> submit({required bool reduceMotion}) async {
    if (state.phase == OnboardingPhase.saving) {
      return;
    }
    state = state.copyWith(
      phase: OnboardingPhase.saving,
      fieldError: null,
      actionError: null,
      timezoneFellBack: false,
    );
    final started = DateTime.now();
    try {
      final timezone = await ref.read(timezoneSourceProvider).ianaName();
      if (!ref.mounted) {
        return;
      }
      final outcome = await ref
          .read(profileRepositoryProvider)
          .save(state.draft, timezone: timezone);
      if (!reduceMotion) {
        final remaining =
            const Duration(milliseconds: 1200) -
            DateTime.now().difference(started);
        if (remaining > Duration.zero) {
          await Future<void>.delayed(remaining);
        }
      }
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        phase: OnboardingPhase.result,
        result: outcome.result,
        timezoneFellBack: outcome.usedUtcFallback,
      );
    } on AppFailure catch (failure) {
      if (!ref.mounted) {
        return;
      }
      _showFailure(failure);
    } on Object {
      if (!ref.mounted) {
        return;
      }
      _showFailure(const UnexpectedResponse(null));
    }
  }

  Future<void> finish() {
    return ref.read(sessionControllerProvider.notifier).completeOnboarding();
  }

  Future<bool> _redirectIfProfileExists() async {
    try {
      final account = await ref.read(authRepositoryProvider).currentAccount();
      if (!ref.mounted) {
        return true;
      }
      if (account.hasProfile) {
        ref.read(sessionControllerProvider.notifier).adopt(account);
        return true;
      }
    } on Object {
      return false;
    }
    return false;
  }

  void _showFailure(AppFailure failure) {
    final fields = failure is ApiProblem
        ? fieldsFromLocs(failure.errors.map((issue) => issue.loc))
        : const <String>[];
    final step = failure is ApiProblem
        ? stepForProfileError(code: failure.code, fields: fields)
        : null;
    if (step != null) {
      final index = state.steps.indexOf(step);
      state = state.copyWith(
        phase: OnboardingPhase.ready,
        stepIndex: index < 0 ? state.stepIndex : index,
        forward: false,
        fieldError: failure,
        actionError: null,
      );
      return;
    }
    state = state.copyWith(
      phase: OnboardingPhase.ready,
      actionError: failure,
      fieldError: null,
    );
  }

  void _edit(ProfileDraft draft) {
    final previous = state.steps;
    final next = onboardingSteps(
      draft,
      clinicianFluidCodes: clinicianFluidCodes(state.reference),
    );
    final index = resolveStepIndex(previous, state.stepIndex, next);
    state = state.copyWith(draft: draft, stepIndex: index, fieldError: null);
  }

  ProfileDraft _reconcileGoal(ProfileDraft draft) {
    final goal = draft.goal;
    if (goal == 'LOSE' &&
        !loseIsOffered(heightCm: draft.heightCm, weightKg: draft.weightKg)) {
      return draft.copyWith(
        goal: null,
        targetWeightKg: null,
        weeklyRateKg: null,
      );
    }
    if (goal == 'GAIN' && !gainIsOffered(weightKg: draft.weightKg)) {
      return draft.copyWith(
        goal: null,
        targetWeightKg: null,
        weeklyRateKg: null,
      );
    }
    if (!paceApplies(goal)) {
      return draft;
    }
    final bounds = targetWeightBounds(
      goal: goal,
      heightCm: draft.heightCm,
      weightKg: draft.weightKg,
    );
    if (bounds == null) {
      return draft.copyWith(
        goal: null,
        targetWeightKg: null,
        weeklyRateKg: null,
      );
    }
    final currentTarget = draft.targetWeightKg;
    final target = currentTarget != null && bounds.contains(currentTarget)
        ? currentTarget
        : defaultTargetKg(
            goal: goal,
            heightCm: draft.heightCm,
            weightKg: draft.weightKg,
          );
    final currentRate = draft.weeklyRateKg;
    final rate =
        currentRate != null &&
            rateIsAllowed(
              goal: goal,
              weightKg: draft.weightKg,
              rateKg: currentRate,
            )
        ? currentRate
        : defaultRateKg(goal: goal, weightKg: draft.weightKg);
    return draft.copyWith(targetWeightKg: target, weeklyRateKg: rate);
  }

  ProfileDraft _clearHiddenAnswers(
    ProfileDraft draft,
    List<String> codes, {
    required bool declined,
  }) {
    final diabetes = codes.contains('DIABETES_T2');
    final fluid = codes.any(clinicianFluidCodes(state.reference).contains);
    return draft.copyWith(
      conditionCodes: codes,
      declinedConditions: declined,
      insulin: diabetes ? draft.insulin : null,
      doctorSetWater: fluid ? draft.doctorSetWater : null,
      waterGoalMl: fluid ? draft.waterGoalMl : null,
    );
  }

  int _shift(int minutes, int delta) {
    final next = (minutes + delta) % 1440;
    return next < 0 ? next + 1440 : next;
  }

  void _reset() {
    _started = false;
    state = const OnboardingState();
  }
}
