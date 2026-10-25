import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/profile.dart';
import '../../../core/api/generated/models/profile_state.dart';
import '../../../core/api/generated/models/targets_view.dart';
import '../../../core/db/personal_data.dart';
import '../../../core/network/app_failure.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/onboarding_steps.dart';
import '../domain/profile_draft.dart';
import '../domain/profile_result.dart';
import 'profile_mapper.dart';
import 'profile_update_body.dart';

/// The conditions onboarding offers; the edit flow keeps the same three.
const editableConditions = <String>{
  'DIABETES_T2',
  'HYPERTENSION',
  'HEART_DISEASE',
};

/// The saved profile as a draft, plus the raw object for the fields the
/// steps do not show (#309).
class EditableProfile {
  const EditableProfile({required this.draft, required this.raw});

  final ProfileDraft draft;
  final Map<String, Object?> raw;
}

abstract interface class ProfileEditor {
  Future<EditableProfile> load();

  Future<ProfileResult> save(ProfileDraft draft, EditableProfile from);
}

int _minutes(String clock) {
  final parts = clock.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// GET /me/profile -> the onboarding draft. The latest weight is shown only
/// for the goal rules; it is not sent back (weight has its own sheet).
ProfileDraft draftFromProfile(Profile profile) {
  final codes = <String>[for (final c in profile.conditions) c.code];
  final conditions = <String>[
    for (final code in codes)
      if (editableConditions.contains(code)) code,
  ];
  final diabetes = conditions.contains('DIABETES_T2');
  final fluid = conditions.any(defaultClinicianFluidCodes.contains);
  return ProfileDraft(
    sex: profile.sex.json,
    birthDate: DateTime(
      profile.birthDate.year,
      profile.birthDate.month,
      profile.birthDate.day,
    ),
    heightCm: profile.heightCm.toDouble(),
    weightKg:
        profile.latestWeightKg?.toDouble() ?? const ProfileDraft().weightKg,
    goal: profile.goalType.json,
    targetWeightKg: profile.targetWeightKg?.toDouble(),
    weeklyRateKg: profile.weeklyRateKg?.toDouble(),
    activity: profile.activityLevel.json,
    conditionCodes: conditions,
    declinedConditions: conditions.isEmpty,
    allergens: <String, String>{
      for (final a in profile.allergens) a.code: a.severity.json ?? 'AVOID',
    },
    insulin: diabetes ? codes.contains('DIABETES_INSULIN') : null,
    wakeMinutes: _minutes(profile.wakeTime),
    sleepMinutes: _minutes(profile.sleepTime),
    doctorSetWater: fluid ? profile.waterGoalMl != null : null,
    waterGoalMl: fluid ? profile.waterGoalMl : null,
  );
}

/// The PUT body of an edit: the onboarding body without the weight, with
/// the saved ingredient preferences, cuisines and time zone kept.
Map<String, Object?> editBody(ProfileDraft draft, EditableProfile from) {
  final timezone = from.raw['timezone'];
  final body = profileUpdateBody(
    draft,
    timezone: timezone is String ? timezone : 'UTC',
  )..remove('current_weight_kg');
  body['ingredient_prefs'] = from.raw['ingredient_prefs'] ?? <Object?>[];
  body['cuisines'] = from.raw['cuisines'] ?? <Object?>[];
  if (!draft.conditionCodes.any(defaultClinicianFluidCodes.contains)) {
    // Not a fluid-limited condition: keep the goal the water tab may have set.
    body['water_goal_ml'] = from.raw['water_goal_ml'];
  }
  return body;
}

final class DioProfileEditor implements ProfileEditor {
  DioProfileEditor(this._dio, {this.onSaved});

  final Dio _dio;
  final Future<void> Function(Map<String, String> allergens)? onSaved;

  @override
  Future<EditableProfile> load() async {
    try {
      final response = await _dio.get<Object>('/api/v1/me/profile');
      final data = _map(response.data, response.statusCode);
      final state = ProfileState.fromJson(data);
      return EditableProfile(
        draft: draftFromProfile(state.profile),
        raw: _map(data['profile'], response.statusCode),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<ProfileResult> save(ProfileDraft draft, EditableProfile from) async {
    try {
      final put = await _dio.put<Object>(
        '/api/v1/me/profile',
        data: editBody(draft, from),
      );
      final state = ProfileState.fromJson(_map(put.data, put.statusCode));
      final targets = await _dio.get<Object>('/api/v1/me/targets');
      await onSaved?.call(draft.allergens);
      return mapProfileResult(
        state,
        TargetsView.fromJson(_map(targets.data, targets.statusCode)),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}

Map<String, Object?> _map(Object? data, int? status) {
  if (data is Map) {
    return data.map(
      (dynamic key, dynamic value) => MapEntry('$key', value as Object?),
    );
  }
  throw UnexpectedResponse(status);
}

final profileEditorProvider = Provider<ProfileEditor>((ref) {
  final personal = ref.watch(personalDataStoreProvider);
  return DioProfileEditor(
    ref.watch(dioProvider),
    onSaved: (Map<String, String> allergens) {
      return personal.replaceAllergens(<({String code, String severity})>[
        for (final entry in allergens.entries)
          (code: entry.key, severity: entry.value),
      ]);
    },
  );
});
