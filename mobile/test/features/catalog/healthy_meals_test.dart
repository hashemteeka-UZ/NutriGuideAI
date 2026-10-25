import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/catalog_snapshot.dart';
import 'package:nutriguide/core/api/generated/models/meal_ingredient_out.dart';
import 'package:nutriguide/core/api/generated/models/nutrient_amount.dart';
import 'package:nutriguide/core/api/generated/models/snapshot_meal.dart';
import 'package:nutriguide/core/db/app_database.dart';
import 'package:nutriguide/features/catalog/data/catalog_mapper.dart';
import 'package:nutriguide/features/catalog/data/healthy_meals.dart';

SnapshotMeal _meal(
  int id,
  double kcal, {
  List<String> tags = const <String>['snack_suitable'],
  List<String> allergens = const <String>[],
}) {
  return SnapshotMeal(
    allergens: allergens,
    carbG: 1,
    datasetVersion: 'batch-1',
    fatG: 1,
    ingredients: const <MealIngredientOut>[],
    kcal: kcal,
    mealId: id,
    name: 'meal $id',
    nutrients: const <NutrientAmount>[],
    proteinG: 1,
    servingGrams: 100,
    servings: 1,
    source: 'test',
    steps: const <String>[],
    tags: tags,
    totalGrams: 100,
  );
}

void main() {
  test(
    'healthy meals skip drinks and allergens, lowest kcal first, id ties',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await replaceCatalogLanguage(
        database,
        lang: 'ar',
        snapshot: CatalogSnapshot(
          datasetVersion: 'cat-1',
          generatedAt: DateTime.utc(2026, 1, 1),
          meals: <SnapshotMeal>[
            _meal(1, 1, tags: <String>['beverage', 'snack_suitable']),
            _meal(2, 35, tags: <String>['beverage']),
            _meal(3, 90, allergens: <String>['MILK']),
            _meal(4, 120),
            _meal(5, 95),
            _meal(6, 95),
            _meal(7, 300),
            _meal(8, 200),
            _meal(9, 500),
          ],
        ),
        etag: '"v"',
        fetchedAt: DateTime.utc(2026, 1, 2),
      );
      await database
          .into(database.userAllergens)
          .insert(
            UserAllergensCompanion.insert(code: 'MILK', severity: 'AVOID'),
          );

      final meals = await healthyMeals(database, 'ar');

      expect(meals.map((meal) => meal.mealId), <int>[5, 6, 4, 8, 7]);
    },
  );
}
