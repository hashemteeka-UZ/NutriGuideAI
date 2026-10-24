import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/catalog_snapshot.dart';
import 'package:nutriguide/core/api/generated/models/meal_ingredient_out.dart';
import 'package:nutriguide/core/api/generated/models/nutrient_amount.dart';
import 'package:nutriguide/core/api/generated/models/nutrient_unit.dart';
import 'package:nutriguide/core/api/generated/models/snapshot_meal.dart';
import 'package:nutriguide/core/db/app_database.dart';
import 'package:nutriguide/features/catalog/data/catalog_mapper.dart';
import 'package:nutriguide/features/catalog/data/catalog_repository_impl.dart';

void main() {
  test('snapshot meal round-trips through the tables into the domain', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final snapshot = CatalogSnapshot(
      datasetVersion: 'cat-1',
      generatedAt: DateTime.utc(2026, 1, 1),
      meals: <SnapshotMeal>[
        const SnapshotMeal(
          allergens: <String>['MILK'],
          carbG: 4,
          datasetVersion: 'batch-1',
          fatG: 6,
          ingredients: <MealIngredientOut>[
            MealIngredientOut(
              gramsPerServing: 50,
              ingredientId: 1,
              isOptional: false,
              name: 'بيض',
            ),
            MealIngredientOut(
              gramsPerServing: 5,
              ingredientId: 2,
              isOptional: true,
              name: 'فلفل',
            ),
          ],
          kcal: 180,
          mealId: 9,
          name: 'شكشوكة',
          nutrients: <NutrientAmount>[
            NutrientAmount(
              code: 'protein',
              unit: NutrientUnit.g,
              perServing: 12,
              per100g: 6,
            ),
            NutrientAmount(
              code: 'not_a_real_code',
              unit: NutrientUnit.mg,
              perServing: 3,
            ),
          ],
          proteinG: 12,
          servingGrams: 200,
          servings: 1,
          source: 'test',
          steps: <String>['اخلط', 'اطبخ'],
          tags: <String>['dinner_suitable'],
          totalGrams: 200,
        ),
      ],
    );

    await replaceCatalogLanguage(
      database,
      lang: 'ar',
      snapshot: snapshot,
      etag: '"v"',
      fetchedAt: DateTime.utc(2026, 1, 2),
    );
    await database
        .into(database.userAllergens)
        .insert(UserAllergensCompanion.insert(code: 'MILK', severity: 'AVOID'));

    final stored = await database
        .customSelect(
          'SELECT cuisine, dish_form, search_key FROM meals WHERE meal_id = 9',
        )
        .getSingle();
    expect(stored.readNullable<String>('cuisine'), isNull);
    expect(stored.readNullable<String>('dish_form'), isNull);
    expect(stored.read<String>('search_key'), 'شكشوكه');

    final codes = await database
        .customSelect(
          'SELECT code FROM meal_nutrients WHERE meal_id = 9 ORDER BY code',
        )
        .get();
    expect(
      codes.map((row) => row.read<String>('code')),
      containsAll(<String>['not_a_real_code', 'protein']),
    );

    final detail = await CatalogRepositoryImpl(
      database,
      locale: () => 'ar',
    ).detail(9);
    expect(detail, isNotNull);
    expect(detail!.cuisineName, isNull);
    expect(detail.ingredients.map((item) => item.name), <String>[
      'بيض',
      'فلفل',
    ]);
    expect(detail.ingredients[1].isOptional, isTrue);
    expect(detail.ingredients[0].gramsPerServing, 50);
    expect(detail.steps, <String>['اخلط', 'اطبخ']);
    expect(detail.nutrients.map((item) => item.code), <String>['protein']);
    expect(detail.warningAllergenCodes, <String>['MILK']);
    expect(detail.iconName, 'crescent-moon');
  });
}
