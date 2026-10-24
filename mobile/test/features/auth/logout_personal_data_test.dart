import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/clients/account_client.dart';
import 'package:nutriguide/core/api/generated/clients/auth_client.dart';
import 'package:nutriguide/core/db/app_database.dart';
import 'package:nutriguide/core/db/personal_data.dart';
import 'package:nutriguide/features/auth/data/auth_repository_impl.dart';
import 'package:nutriguide/features/auth/data/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/memory_secure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'logout clears meal prefs and allergens and keeps the catalog',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        accountOwnerPreferenceKey: '4',
      });
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final personal = PersonalDataStore(database);
      await database
          .into(database.meals)
          .insert(
            MealsCompanion.insert(
              lang: 'ar',
              mealId: 7,
              name: 'شكشوكة',
              searchKey: 'شكشوكه',
              servingGrams: 1,
              servings: 1,
              totalGrams: 1,
              kcal: 1,
              proteinG: 1,
              carbG: 1,
              fatG: 1,
              source: 'test',
              datasetVersion: 'v',
            ),
          );
      await personal.replacePrefs(
        <({int mealId, String stance, DateTime updatedAt})>[
          (mealId: 7, stance: 'LIKE', updatedAt: DateTime.utc(2026, 1, 1)),
        ],
      );
      await personal.replaceAllergens(<({String code, String severity})>[
        (code: 'MILK', severity: 'AVOID'),
      ]);

      final repository = AuthRepositoryImpl(
        auth: AuthClient(Dio()),
        account: AccountClient(Dio()),
        tokens: SecureTokenStore(MemorySecure()),
        personal: personal,
      );
      await repository.logout();

      expect(await database.select(database.localMealPrefs).get(), isEmpty);
      expect(await database.select(database.userAllergens).get(), isEmpty);
      expect(await database.select(database.meals).get(), hasLength(1));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(accountOwnerPreferenceKey), isNull);
    },
  );
}
