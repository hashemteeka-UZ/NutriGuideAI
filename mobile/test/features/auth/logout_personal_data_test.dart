import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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
      final now = DateTime.utc(2026, 10, 24);
      await database
          .into(database.plans)
          .insert(
            PlansCompanion.insert(
              planDate: '2026-10-24',
              planId: 1,
              algorithmVersion: 'cp-sat',
              createdAt: now,
              kcal: 1800,
              proteinG: 90,
              carbG: 180,
              fatG: 60,
              fiberG: 30,
              kcalWithin10pct: true,
              fetchedAt: now,
            ),
          );
      await database
          .into(database.planItems)
          .insert(
            PlanItemsCompanion.insert(
              planItemId: const Value(3),
              planDate: '2026-10-24',
              position: 0,
              slot: 'BREAKFAST',
              mealId: 7,
              mealName: 'شكشوكة',
              servingsMultiplier: 1,
              grams: 200,
              kcal: 400,
              proteinG: 20,
              carbG: 30,
              fatG: 15,
              reasonCodes: '[]',
              wasSwapped: false,
              logged: false,
            ),
          );
      await database
          .into(database.planUnmetMinimums)
          .insert(
            PlanUnmetMinimumsCompanion.insert(
              planDate: '2026-10-24',
              nutrient: 'fiber',
              minimum: 30,
            ),
          );
      await database
          .into(database.mealWindows)
          .insert(
            MealWindowsCompanion.insert(
              windowDate: '2026-10-24',
              slot: 'BREAKFAST',
              start: '07:00',
              end: '09:00',
            ),
          );
      await database
          .into(database.daySummaries)
          .insert(
            DaySummariesCompanion.insert(
              summaryDate: '2026-10-24',
              planItemsTotal: 4,
              planItemsConsumed: 0,
              totalMl: 0,
              requiresClinician: false,
              fetchedAt: now,
            ),
          );
      await database
          .into(database.shoppingLists)
          .insert(
            ShoppingListsCompanion.insert(
              rangeKey: '2026-10-24_2026-10-30',
              fetchedAt: now,
            ),
          );
      await database
          .into(database.shoppingItems)
          .insert(
            ShoppingItemsCompanion.insert(
              rangeKey: '2026-10-24_2026-10-30',
              ingredientId: 1,
              name: 'طماطم',
              grams: 200,
              meals: 2,
              checked: true,
            ),
          );

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
      expect(await database.select(database.plans).get(), isEmpty);
      expect(await database.select(database.planItems).get(), isEmpty);
      expect(await database.select(database.planUnmetMinimums).get(), isEmpty);
      expect(await database.select(database.mealWindows).get(), isEmpty);
      expect(await database.select(database.daySummaries).get(), isEmpty);
      expect(await database.select(database.shoppingLists).get(), isEmpty);
      expect(await database.select(database.shoppingItems).get(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(accountOwnerPreferenceKey), isNull);
    },
  );
}
