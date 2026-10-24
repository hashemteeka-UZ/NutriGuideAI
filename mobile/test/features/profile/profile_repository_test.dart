import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/activity_level.dart';
import 'package:nutriguide/core/api/generated/models/goal_type.dart';
import 'package:nutriguide/core/api/generated/models/profile.dart';
import 'package:nutriguide/core/api/generated/models/profile_state.dart';
import 'package:nutriguide/core/api/generated/models/screening.dart';
import 'package:nutriguide/core/api/generated/models/sex.dart';
import 'package:nutriguide/core/api/generated/models/target.dart';
import 'package:nutriguide/core/api/generated/models/target_reason.dart';
import 'package:nutriguide/core/api/generated/models/targets_view.dart';
import 'package:nutriguide/core/api/generated/models/water_goal.dart';
import 'package:nutriguide/core/api/generated/models/water_goal_source.dart';
import 'package:nutriguide/core/network/app_failure.dart';
import 'package:nutriguide/features/profile/data/profile_api.dart';
import 'package:nutriguide/features/profile/data/profile_repository.dart';
import 'package:nutriguide/features/profile/domain/profile_draft.dart';

void main() {
  final draft = ProfileDraft(
    sex: 'FEMALE',
    birthDate: DateTime.utc(1996, 4, 12),
    goal: 'LOSE',
    activity: 'LIGHT',
    targetWeightKg: 65,
    weeklyRateKg: 0.5,
    declinedConditions: true,
  );

  test('an eligible save reads water from targets', () async {
    final api = _Api(
      state: _state(eligible: true),
      targets: _targets(goalMl: 1600),
    );
    final outcome = await ProfileRepositoryImpl(api)
        .save(draft, timezone: 'Asia/Riyadh');

    expect(outcome.result.showPersonalPlan, isTrue);
    expect(outcome.result.target?.kcal, 1800);
    expect(outcome.result.target?.bmrKcal, 1500);
    expect(outcome.result.target?.tdeeKcal, 2325);
    expect(outcome.result.water.goalMl, 1600);
    expect(outcome.usedUtcFallback, isFalse);
    expect(api.bodies.single['timezone'], 'Asia/Riyadh');
  });

  test('an ineligible save keeps a null target and the reasons', () async {
    final outcome = await ProfileRepositoryImpl(
      _Api(
        state: _state(eligible: false, reasons: const <String>['UNDER_18']),
        targets: _targets(goalMl: null, requiresClinician: false),
      ),
    ).save(draft, timezone: 'UTC');

    expect(outcome.result.eligible, isFalse);
    expect(outcome.result.target, isNull);
    expect(outcome.result.reasons, <String>['UNDER_18']);
  });

  test('TARGET_VALIDATION is surfaced for the caller to map', () async {
    final failure = const ApiProblem(
      status: 422,
      code: 'TARGET_VALIDATION',
      title: null,
      detail: null,
      requestId: null,
      retryAfter: null,
    );

    await expectLater(
      ProfileRepositoryImpl(
        _Api(
          state: _state(eligible: true),
          targets: _targets(),
          error: failure,
        ),
      ).save(draft, timezone: 'UTC'),
      throwsA(
        isA<ApiProblem>().having(
          (problem) => problem.code,
          'code',
          'TARGET_VALIDATION',
        ),
      ),
    );
  });

  test('INVALID_TIMEZONE is retried once with UTC', () async {
    final api = _Api(
      state: _state(eligible: true),
      targets: _targets(),
      timezoneFailures: 1,
    );

    final outcome = await ProfileRepositoryImpl(api)
        .save(draft, timezone: 'Asia/Riyadh');

    expect(api.bodies, hasLength(2));
    expect(api.bodies.first['timezone'], 'Asia/Riyadh');
    expect(api.bodies.last['timezone'], 'UTC');
    expect(outcome.usedUtcFallback, isTrue);
    expect(outcome.result.target?.kcal, 1800);
  });
}

ProfileState _state({
  required bool eligible,
  List<String> reasons = const <String>[],
}) {
  return ProfileState(
    profile: Profile(
      activityLevel: ActivityLevel.light,
      allergens: const [],
      birthDate: DateTime.utc(1996, 4, 12),
      conditions: const [],
      cuisines: const <String>[],
      goalType: GoalType.lose,
      heightCm: 165,
      ingredientPrefs: const [],
      sex: Sex.female,
      sleepTime: '23:00',
      timezone: 'Asia/Riyadh',
      wakeTime: '07:00',
    ),
    screening: Screening(eligible: eligible, reasons: reasons),
    target: eligible
        ? Target(
            basedOnWeightKg: 80,
            bmrKcal: 1500,
            carbG: 200,
            fatG: 60,
            fiberG: 25,
            formulaVersion: 'targets_v1',
            kcal: 1800,
            proteinG: 120,
            reason: TargetReason.initial,
            targetId: 1,
            tdeeKcal: 2325,
            validFrom: DateTime.utc(2026, 10, 24),
            wasFloorApplied: false,
          )
        : null,
  );
}

TargetsView _targets({int? goalMl = 2000, bool requiresClinician = false}) {
  return TargetsView(
    screening: const Screening(eligible: true, reasons: <String>[]),
    target: null,
    water: WaterGoal(
      goalMl: goalMl,
      remindersDefaultOff: false,
      requiresClinician: requiresClinician,
      source: goalMl == null
          ? WaterGoalSource.none
          : WaterGoalSource.valueDefault,
    ),
  );
}

final class _Api implements ProfileApi {
  _Api({
    required this.state,
    required this.targets,
    this.error,
    this.timezoneFailures = 0,
  });

  final ProfileState state;
  final TargetsView targets;
  final AppFailure? error;
  int timezoneFailures;
  final bodies = <Map<String, Object?>>[];

  @override
  Future<ProfileState> putProfile(Map<String, Object?> body) async {
    bodies.add(body);
    if (timezoneFailures > 0 && body['timezone'] != 'UTC') {
      timezoneFailures -= 1;
      throw _problem('INVALID_TIMEZONE');
    }
    final failure = error;
    if (failure != null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/me/profile'),
        error: failure,
      );
    }
    return state;
  }

  @override
  Future<TargetsView> getTargets() async => targets;
}

DioException _problem(String code) {
  return DioException(
    requestOptions: RequestOptions(path: '/api/v1/me/profile'),
    error: ApiProblem(
      status: 422,
      code: code,
      title: null,
      detail: null,
      requestId: null,
      retryAfter: null,
    ),
  );
}
