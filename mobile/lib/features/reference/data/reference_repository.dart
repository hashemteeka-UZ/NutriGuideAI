import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/generated/clients/reference_client.dart';
import '../../../core/api/generated/models/reference.dart';
import '../../../core/network/app_failure.dart';
import '../domain/reference_data.dart';

final class ReferenceRepositoryImpl implements ReferenceRepository {
  ReferenceRepositoryImpl(this._client);

  final ReferenceClient _client;
  ReferenceData? _cached;
  String? _locale;

  @override
  Future<ReferenceData> load({required String locale}) async {
    final cached = _cached;
    if (cached != null && _locale == locale) {
      return cached;
    }
    try {
      final data = mapReference(await _client.getReference());
      _cached = data;
      _locale = locale;
      return data;
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}

ReferenceData mapReference(Reference raw) {
  return ReferenceData(
    conditions: <ConditionInfo>[
      for (final item in raw.healthConditions)
        ConditionInfo(
          code: item.code,
          name: item.name,
          isSupported: item.isSupported,
          fluidGoalRequiresClinician: item.fluidGoalRequiresClinician,
        ),
    ],
    allergens: <AllergenInfo>[
      for (final item in raw.allergens)
        AllergenInfo(code: item.code, name: item.name),
    ],
    activityLevels: <String>[
      for (final level in raw.activityLevels)
        if (level.json != null) level.json!,
    ],
    goals: <String>[
      for (final goal in raw.goalTypes)
        if (goal.json != null) goal.json!,
    ],
    sexes: <String>[
      for (final sex in raw.sexes)
        if (sex.json != null) sex.json!,
    ],
  );
}

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  return ReferenceRepositoryImpl(ref.watch(referenceClientProvider));
});
