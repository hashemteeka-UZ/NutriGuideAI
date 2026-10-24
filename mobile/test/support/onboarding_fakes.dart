import 'package:nutriguide/core/time/timezone_source.dart';
import 'package:nutriguide/features/profile/domain/profile_draft.dart';
import 'package:nutriguide/features/profile/domain/profile_repository.dart';
import 'package:nutriguide/features/profile/domain/profile_result.dart';
import 'package:nutriguide/features/reference/domain/reference_data.dart';

const sampleReference = ReferenceData(
  conditions: <ConditionInfo>[
    ConditionInfo(
      code: 'DIABETES_T2',
      name: 'السكري من النوع الثاني',
      isSupported: true,
      fluidGoalRequiresClinician: false,
    ),
    ConditionInfo(
      code: 'HYPERTENSION',
      name: 'ارتفاع ضغط الدم',
      isSupported: true,
      fluidGoalRequiresClinician: false,
    ),
    ConditionInfo(
      code: 'HEART_DISEASE',
      name: 'مرض القلب',
      isSupported: true,
      fluidGoalRequiresClinician: true,
    ),
    ConditionInfo(
      code: 'DIABETES_INSULIN',
      name: 'إنسولين',
      isSupported: false,
      fluidGoalRequiresClinician: false,
    ),
  ],
  allergens: <AllergenInfo>[
    AllergenInfo(code: 'MILK', name: 'الحليب'),
    AllergenInfo(code: 'GLUTEN', name: 'الغلوتين'),
    AllergenInfo(code: 'ZZZ', name: 'مكون غير معروف'),
  ],
  activityLevels: <String>['SEDENTARY', 'LIGHT', 'MODERATE', 'HIGH', 'ATHLETE'],
  goals: <String>['LOSE', 'MAINTAIN', 'GAIN', 'MUSCLE'],
  sexes: <String>['MALE', 'FEMALE'],
);

DailyTarget sampleTarget({bool floorApplied = false}) {
  return DailyTarget(
    kcal: 1800,
    proteinG: 120,
    carbG: 200,
    fatG: 60,
    fiberG: 25,
    bmrKcal: 1500,
    tdeeKcal: 2325,
    floorApplied: floorApplied,
    basedOnWeightKg: 80,
  );
}

ProfileResult sampleResult({
  bool eligible = true,
  bool floorApplied = false,
  List<String> reasons = const <String>[],
  int? waterMl = 2000,
  bool requiresClinician = false,
  String goalType = 'LOSE',
}) {
  final showTarget = eligible;
  return ProfileResult(
    eligible: eligible,
    reasons: reasons,
    goalType: goalType,
    target: showTarget ? sampleTarget(floorApplied: floorApplied) : null,
    water: WaterView(
      goalMl: waterMl,
      source: waterMl == null ? 'NONE' : 'DEFAULT',
      requiresClinician: requiresClinician,
    ),
  );
}

final class FakeReferenceRepository implements ReferenceRepository {
  FakeReferenceRepository(this.data, {this.error});

  final ReferenceData data;
  Object? error;
  int calls = 0;
  final locales = <String>[];

  @override
  Future<ReferenceData> load({required String locale}) async {
    calls += 1;
    locales.add(locale);
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return data;
  }
}

final class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.outcome, this.error});

  ProfileSaveOutcome? outcome;
  Object? error;
  int calls = 0;
  ProfileDraft? lastDraft;
  String? lastTimezone;

  @override
  Future<ProfileSaveOutcome> save(
    ProfileDraft draft, {
    required String timezone,
  }) async {
    calls += 1;
    lastDraft = draft;
    lastTimezone = timezone;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return outcome ??
        ProfileSaveOutcome(result: sampleResult(), usedUtcFallback: false);
  }
}

final class FakeTimezone implements TimezoneSource {
  FakeTimezone(this.name);

  final String name;

  @override
  Future<String> ianaName() async => name;
}
