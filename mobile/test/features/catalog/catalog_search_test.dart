import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/db/app_database.dart';
import 'package:nutriguide/features/catalog/data/catalog_repository_impl.dart';
import 'package:nutriguide/features/catalog/domain/meal.dart';

void main() {
  late AppDatabase database;
  late CatalogRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = CatalogRepositoryImpl(database, locale: () => 'ar');
    await _seed(database);
  });

  tearDown(() => database.close());

  test('ranks exact, then prefix, then word prefix, then contains', () async {
    final page = await repository.browse(const MealQuery(text: 'tea'));
    expect(page.meals.map((meal) => meal.mealId), <int>[1, 2, 3, 4]);
  });

  test('percent and underscore in the query are literal', () async {
    final percent = await repository.browse(const MealQuery(text: '%'));
    expect(percent.meals.map((meal) => meal.mealId), <int>[5]);

    final underscore = await repository.browse(const MealQuery(text: '_'));
    expect(underscore.meals.map((meal) => meal.mealId), <int>[6]);
  });

  test('slot, cuisine, and allergen filters combine', () async {
    final hidden = await repository.browse(
      const MealQuery(
        text: 'tea',
        occasionTag: breakfastTag,
        cuisineCode: 'eg',
      ),
    );
    expect(hidden.meals.map((meal) => meal.mealId), <int>[1]);

    final shown = await repository.browse(
      const MealQuery(
        text: 'tea',
        occasionTag: breakfastTag,
        cuisineCode: 'eg',
        hideAvoided: false,
      ),
    );
    expect(shown.meals.map((meal) => meal.mealId), <int>[1, 7]);
    expect(
      shown.meals.singleWhere((meal) => meal.mealId == 7).allergenWarning,
      isTrue,
    );
  });
}

Future<void> _seed(AppDatabase database) async {
  await database
      .into(database.catalogMeta)
      .insert(
        CatalogMetaCompanion.insert(
          lang: 'ar',
          etag: 'e',
          datasetVersion: 'v',
          mealCount: 7,
          fetchedAt: DateTime.utc(2026, 1, 1),
        ),
      );
  await database
      .into(database.cuisines)
      .insert(CuisinesCompanion.insert(lang: 'ar', code: 'eg', name: 'مصري'));
  const rows = <(int, String, String, String?)>[
    (1, 'tea', 'tea', 'eg'),
    (2, 'teacup', 'teacup', 'eg'),
    (3, 'green tea', 'green tea', 'sy'),
    (4, 'hotteatime', 'hotteatime', 'sy'),
    (5, '100%', '100%', 'eg'),
    (6, 'a_b', 'a_b', 'eg'),
    (7, 'milktea', 'milktea', 'eg'),
  ];
  for (final row in rows) {
    await database
        .into(database.meals)
        .insert(
          MealsCompanion.insert(
            lang: 'ar',
            mealId: row.$1,
            name: row.$2,
            searchKey: row.$3,
            cuisine: Value(row.$4),
            servingGrams: 100,
            servings: 1,
            totalGrams: 100,
            kcal: 100,
            proteinG: 10,
            carbG: 10,
            fatG: 10,
            source: 'test',
            datasetVersion: 'v',
          ),
        );
  }
  Future<void> tag(int mealId, String tag) {
    return database
        .into(database.mealTags)
        .insert(MealTagsCompanion.insert(lang: 'ar', mealId: mealId, tag: tag));
  }

  await tag(1, breakfastTag);
  await tag(2, lunchTag);
  await tag(3, breakfastTag);
  await tag(4, breakfastTag);
  await tag(7, breakfastTag);
  await database
      .into(database.mealAllergens)
      .insert(
        MealAllergensCompanion.insert(lang: 'ar', mealId: 7, code: 'MILK'),
      );
  await database
      .into(database.userAllergens)
      .insert(UserAllergensCompanion.insert(code: 'MILK', severity: 'AVOID'));
}
