import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: <Type>[
    CatalogMeta,
    Meals,
    MealTags,
    MealAllergens,
    MealIngredients,
    MealNutrients,
    MealSteps,
    Cuisines,
    LocalMealPrefs,
    UserAllergens,
    Plans,
    PlanItems,
    PlanUnmetMinimums,
    MealWindows,
    DaySummaries,
    ShoppingLists,
    ShoppingItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Version 1 has no tables. Creating every current table here would
      // make a 1 -> 2 migration look like version 3.
      if (from < 2) {
        await m.createTable(catalogMeta);
        await m.createTable(meals);
        await m.createIndex(mealsLangSearchKey);
        await m.createTable(mealTags);
        await m.createTable(mealAllergens);
        await m.createTable(mealIngredients);
        await m.createTable(mealNutrients);
        await m.createTable(mealSteps);
        await m.createTable(cuisines);
        await m.createTable(localMealPrefs);
        await m.createTable(userAllergens);
      }
      if (from < 3 && to >= 3) {
        await m.createTable(plans);
        await m.createTable(planItems);
        await m.createTable(planUnmetMinimums);
        await m.createTable(mealWindows);
        await m.createTable(daySummaries);
        await m.createTable(shoppingLists);
        await m.createTable(shoppingItems);
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
