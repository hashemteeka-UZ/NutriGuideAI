import 'package:drift/drift.dart';

import 'app_database.steps.dart';
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
    Outbox,
    ConsumptionLogs,
    WaterLogs,
    Weights,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    // Each step creates tables as they were in its own version, so a table
    // made at version 3 does not get a column added at version 5 too early.
    onUpgrade: stepByStep(
      from1To2: (Migrator m, Schema2 schema) async {
        await m.createTable(schema.catalogMeta);
        await m.createTable(schema.meals);
        await m.createIndex(schema.mealsLangSearchKey);
        await m.createTable(schema.mealTags);
        await m.createTable(schema.mealAllergens);
        await m.createTable(schema.mealIngredients);
        await m.createTable(schema.mealNutrients);
        await m.createTable(schema.mealSteps);
        await m.createTable(schema.cuisines);
        await m.createTable(schema.mealPrefs);
        await m.createTable(schema.userAllergens);
      },
      from2To3: (Migrator m, Schema3 schema) async {
        await m.createTable(schema.plans);
        await m.createTable(schema.planItems);
        await m.createTable(schema.planUnmetMinimums);
        await m.createTable(schema.mealWindows);
        await m.createTable(schema.daySummaries);
        await m.createTable(schema.shoppingLists);
        await m.createTable(schema.shoppingItems);
      },
      from3To4: (Migrator m, Schema4 schema) async {
        await m.createTable(schema.outbox);
        await m.createTable(schema.consumptionLogs);
      },
      from4To5: (Migrator m, Schema5 schema) async {
        await m.addColumn(schema.daySummaries, schema.daySummaries.waterSource);
        await m.createTable(schema.waterLogs);
        await m.createTable(schema.weights);
      },
    ),
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
