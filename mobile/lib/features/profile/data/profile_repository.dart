import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/profile_state.dart';
import '../../../core/api/generated/models/targets_view.dart';
import '../../../core/db/personal_data.dart';
import '../../../core/network/app_failure.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/profile_draft.dart';
import '../domain/profile_repository.dart';
import 'profile_api.dart';
import 'profile_mapper.dart';
import 'profile_update_body.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api, {this.onSaved});

  final ProfileApi _api;
  final Future<void> Function(Map<String, String> allergens)? onSaved;

  @override
  Future<ProfileSaveOutcome> save(
    ProfileDraft draft, {
    required String timezone,
  }) async {
    try {
      final state = await _put(profileUpdateBody(draft, timezone: timezone));
      final targets = await _targets();
      await onSaved?.call(draft.allergens);
      return ProfileSaveOutcome(
        result: mapProfileResult(state, targets),
        usedUtcFallback: false,
      );
    } on AppFailure catch (failure) {
      final retry =
          failure is ApiProblem &&
          failure.code == 'INVALID_TIMEZONE' &&
          timezone != 'UTC';
      if (!retry) {
        rethrow;
      }
      final state = await _put(profileUpdateBody(draft, timezone: 'UTC'));
      final targets = await _targets();
      await onSaved?.call(draft.allergens);
      return ProfileSaveOutcome(
        result: mapProfileResult(state, targets),
        usedUtcFallback: true,
      );
    }
  }

  Future<ProfileState> _put(Map<String, Object?> body) async {
    try {
      return await _api.putProfile(body);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<TargetsView> _targets() async {
    try {
      return await _api.getTargets();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final personal = ref.watch(personalDataStoreProvider);
  return ProfileRepositoryImpl(
    DioProfileApi(ref.watch(dioProvider)),
    onSaved: (Map<String, String> allergens) {
      return personal.replaceAllergens([
        for (final entry in allergens.entries)
          (code: entry.key, severity: entry.value),
      ]);
    },
  );
});
