import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';
import 'database_provider.dart';

const accountOwnerPreferenceKey = 'ng.account_id';

/// Personal rows and the id of the account they belong to.
class PersonalDataStore {
  PersonalDataStore(
    this._database, {
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  final AppDatabase _database;
  final Future<SharedPreferences> Function() _preferences;

  /// Bumped when personal rows are dropped so an in-flight sync cannot
  /// write them back after logout or an account switch.
  int generation = 0;

  Future<void> clear() async {
    generation += 1;
    await _deleteRows();
    final preferences = await _preferences();
    await preferences.remove(accountOwnerPreferenceKey);
  }

  /// Drops personal rows when [userId] is a different account.
  Future<void> claim(int? userId) async {
    if (userId == null) {
      return;
    }
    final preferences = await _preferences();
    final next = '$userId';
    final previous = preferences.getString(accountOwnerPreferenceKey);
    if (previous != null && previous != next) {
      generation += 1;
      await _deleteRows();
    }
    await preferences.setString(accountOwnerPreferenceKey, next);
  }

  Future<void> replaceAllergens(
    List<({String code, String severity})> rows,
  ) async {
    final seen = generation;
    await _database.transaction(() async {
      if (seen != generation) {
        return;
      }
      await _database.delete(_database.userAllergens).go();
      await _database.batch((batch) {
        batch.insertAll(_database.userAllergens, [
          for (final row in rows)
            UserAllergensCompanion.insert(
              code: row.code,
              severity: row.severity,
            ),
        ]);
      });
    });
  }

  Future<void> replacePrefs(
    List<({int mealId, String stance, DateTime updatedAt})> rows,
  ) async {
    final seen = generation;
    await _database.transaction(() async {
      if (seen != generation) {
        return;
      }
      await _database.delete(_database.localMealPrefs).go();
      await _database.batch((batch) {
        batch.insertAll(_database.localMealPrefs, [
          for (final row in rows)
            LocalMealPrefsCompanion.insert(
              mealId: Value(row.mealId),
              stance: row.stance,
              updatedAt: row.updatedAt.toUtc(),
            ),
        ]);
      });
    });
  }

  Future<void> _deleteRows() async {
    await _database.transaction(() async {
      await _database.delete(_database.localMealPrefs).go();
      await _database.delete(_database.userAllergens).go();
    });
  }
}

final personalDataStoreProvider = Provider<PersonalDataStore>((ref) {
  return PersonalDataStore(ref.watch(appDatabaseProvider));
});
