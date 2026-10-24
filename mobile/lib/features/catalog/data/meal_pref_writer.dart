import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/clients/meal_prefs_client.dart';
import '../../../core/api/generated/models/meal_pref_update.dart';
import '../../../core/api/generated/models/meal_stance.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/network/app_failure.dart';
import '../../../core/network/dio_provider.dart';
import 'catalog_sync.dart';

abstract interface class MealPrefRemote {
  Future<void> put(int mealId, String stance);

  Future<void> delete(int mealId);
}

final class DioMealPrefRemote implements MealPrefRemote {
  DioMealPrefRemote(this._dio);

  final Dio _dio;

  @override
  Future<void> put(int mealId, String stance) {
    return MealPrefsClient(_dio).setMealPref(
      mealId: mealId,
      body: MealPrefUpdate(stance: MealStance.fromJson(stance)),
    );
  }

  @override
  Future<void> delete(int mealId) {
    return MealPrefsClient(_dio).deleteMealPref(mealId: mealId);
  }
}

/// Writes the stance locally first, then sends one PUT or DELETE.
final class MealPrefWriter {
  MealPrefWriter({
    required this._database,
    required this._remote,
    required this._onMealMissing,
    this._onChanged,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase _database;
  final MealPrefRemote _remote;
  final Future<void> Function() _onMealMissing;
  final void Function()? _onChanged;
  final DateTime Function() _now;

  Future<void> apply({required int mealId, required String? stance}) async {
    final previous = await _read(mealId);
    await _write(mealId, stance, updatedAt: _now().toUtc());
    _onChanged?.call();
    try {
      if (stance == null) {
        await _remote.delete(mealId);
      } else {
        await _remote.put(mealId, stance);
      }
    } on Object catch (error) {
      await _write(mealId, previous?.stance, updatedAt: previous?.updatedAt);
      _onChanged?.call();
      if (_missing(error)) {
        await _onMealMissing();
      }
      rethrow;
    }
  }

  Future<({String stance, DateTime updatedAt})?> _read(int mealId) async {
    final row = await (_database.select(
      _database.localMealPrefs,
    )..where((table) => table.mealId.equals(mealId))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return (stance: row.stance, updatedAt: row.updatedAt);
  }

  Future<void> _write(int mealId, String? stance, {DateTime? updatedAt}) async {
    if (stance == null) {
      await (_database.delete(
        _database.localMealPrefs,
      )..where((table) => table.mealId.equals(mealId))).go();
      return;
    }
    await _database
        .into(_database.localMealPrefs)
        .insertOnConflictUpdate(
          LocalMealPrefsCompanion.insert(
            mealId: Value(mealId),
            stance: stance,
            updatedAt: (updatedAt ?? _now()).toUtc(),
          ),
        );
  }
}

bool _missing(Object error) {
  final failure = error is DioException ? mapDioException(error) : error;
  return failure is ApiProblem && failure.code == 'MEAL_NOT_FOUND';
}

class MealRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final mealRevisionProvider = NotifierProvider<MealRevision, int>(
  MealRevision.new,
);

final mealPrefWriterProvider = Provider<MealPrefWriter>((ref) {
  return MealPrefWriter(
    database: ref.watch(appDatabaseProvider),
    remote: DioMealPrefRemote(ref.watch(dioProvider)),
    onMealMissing: () {
      return ref
          .read(catalogSyncProvider)
          .sync(lang: ref.read(localeCodeProvider).code);
    },
    onChanged: () {
      ref.read(mealRevisionProvider.notifier).bump();
    },
  );
});
