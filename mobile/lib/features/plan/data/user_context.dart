import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/clients/profile_client.dart';
import '../../../core/api/generated/models/ingredient_stance.dart';
import '../../../core/network/app_failure.dart';
import '../domain/cached_user.dart';

class UserContextController extends Notifier<CachedUser?> {
  @override
  CachedUser? build() => null;

  void replace(CachedUser user) {
    state = user;
  }

  void markIneligible() {
    final current = state;
    if (current == null) {
      state = const CachedUser(
        eligible: false,
        goalType: 'MAINTAIN',
        conditions: <String>[],
        allergenCodes: <String>[],
        hasDislike: false,
      );
      return;
    }
    state = current.copyWith(eligible: false);
  }

  Future<void> refresh(Dio dio) async {
    try {
      final client = ProfileClient(dio);
      final profile = await client.getProfile();
      final targets = await client.getTargets();
      final target = targets.target;
      state = CachedUser(
        eligible: targets.screening.eligible,
        goalType: profile.profile.goalType.json ?? 'MAINTAIN',
        target: target == null
            ? null
            : EnergyTarget(
                kcal: target.kcal,
                bmrKcal: target.bmrKcal.toDouble(),
                tdeeKcal: target.tdeeKcal.toDouble(),
                targetId: target.targetId,
                proteinG: target.proteinG.toDouble(),
                carbG: target.carbG.toDouble(),
                fatG: target.fatG.toDouble(),
              ),
        sex: profile.profile.sex.json,
        latestWeightKg: profile.profile.latestWeightKg?.toDouble(),
        targetWeightKg: profile.profile.targetWeightKg?.toDouble(),
        conditions: <String>[
          for (final condition in profile.profile.conditions) condition.code,
        ],
        allergenCodes: <String>[
          for (final allergen in profile.profile.allergens) allergen.code,
        ],
        hasDislike: profile.profile.ingredientPrefs.any(
          (pref) => pref.stance == IngredientStance.dislike,
        ),
      );
    } on DioException catch (error) {
      final failure = mapDioException(error);
      if (failure is ApiProblem && failure.code == 'NOT_ELIGIBLE') {
        markIneligible();
      }
    } on Object {
      // Keep the copy already in memory.
    }
  }
}

final userContextProvider =
    NotifierProvider<UserContextController, CachedUser?>(
      UserContextController.new,
    );
