import 'package:drift/drift.dart';

import '../../../core/api/generated/models/catalog_snapshot.dart';
import '../../../core/api/generated/models/snapshot_meal.dart';
import '../../../core/db/app_database.dart';
import '../domain/search_normalizer.dart';

class CatalogRows {
  const CatalogRows({
    required this.meals,
    required this.tags,
    required this.allergens,
    required this.ingredients,
    required this.nutrients,
    required this.steps,
  });

  final List<MealsCompanion> meals;
  final List<MealTagsCompanion> tags;
  final List<MealAllergensCompanion> allergens;
  final List<MealIngredientsCompanion> ingredients;
  final List<MealNutrientsCompanion> nutrients;
  final List<MealStepsCompanion> steps;
}

CatalogRows catalogRows(String lang, CatalogSnapshot snapshot) {
  final meals = <MealsCompanion>[];
  final tags = <MealTagsCompanion>[];
  final allergens = <MealAllergensCompanion>[];
  final ingredients = <MealIngredientsCompanion>[];
  final nutrients = <MealNutrientsCompanion>[];
  final steps = <MealStepsCompanion>[];
  for (final meal in snapshot.meals) {
    meals.add(_meal(lang, meal));
    for (final tag in meal.tags) {
      tags.add(
        MealTagsCompanion.insert(lang: lang, mealId: meal.mealId, tag: tag),
      );
    }
    for (final code in meal.allergens) {
      allergens.add(
        MealAllergensCompanion.insert(
          lang: lang,
          mealId: meal.mealId,
          code: code,
        ),
      );
    }
    for (var i = 0; i < meal.ingredients.length; i++) {
      final item = meal.ingredients[i];
      ingredients.add(
        MealIngredientsCompanion.insert(
          lang: lang,
          mealId: meal.mealId,
          position: i,
          ingredientId: item.ingredientId,
          name: item.name,
          gramsPerServing: item.gramsPerServing.toDouble(),
          isOptional: item.isOptional,
        ),
      );
    }
    for (final amount in meal.nutrients) {
      final unit = amount.unit.json;
      if (unit == null) {
        continue;
      }
      nutrients.add(
        MealNutrientsCompanion.insert(
          lang: lang,
          mealId: meal.mealId,
          code: amount.code,
          unit: unit,
          per100g: Value(amount.per100g?.toDouble()),
          perServing: Value(amount.perServing?.toDouble()),
        ),
      );
    }
    for (var i = 0; i < meal.steps.length; i++) {
      steps.add(
        MealStepsCompanion.insert(
          lang: lang,
          mealId: meal.mealId,
          position: i,
          stepText: meal.steps[i],
        ),
      );
    }
  }
  return CatalogRows(
    meals: meals,
    tags: tags,
    allergens: allergens,
    ingredients: ingredients,
    nutrients: nutrients,
    steps: steps,
  );
}

MealsCompanion _meal(String lang, SnapshotMeal meal) {
  return MealsCompanion.insert(
    lang: lang,
    mealId: meal.mealId,
    name: meal.name,
    searchKey: normalizeSearch(meal.name),
    cuisine: Value(meal.cuisine),
    dishForm: Value(meal.dishForm?.json),
    servingGrams: meal.servingGrams.toDouble(),
    servings: meal.servings,
    totalGrams: meal.totalGrams.toDouble(),
    kcal: meal.kcal.toDouble(),
    proteinG: meal.proteinG.toDouble(),
    carbG: meal.carbG.toDouble(),
    fatG: meal.fatG.toDouble(),
    source: meal.source,
    datasetVersion: meal.datasetVersion,
  );
}

/// Replaces one language. A failure rolls the transaction back.
Future<void> replaceCatalogLanguage(
  AppDatabase database, {
  required String lang,
  required CatalogSnapshot snapshot,
  required String etag,
  required DateTime fetchedAt,
}) async {
  final rows = catalogRows(lang, snapshot);
  await database.transaction(() async {
    await _deleteLanguage(database, lang);
    await database.batch((batch) {
      batch.insertAll(database.meals, rows.meals);
      batch.insertAll(database.mealTags, rows.tags);
      batch.insertAll(database.mealAllergens, rows.allergens);
      batch.insertAll(database.mealIngredients, rows.ingredients);
      batch.insertAll(database.mealNutrients, rows.nutrients);
      batch.insertAll(database.mealSteps, rows.steps);
    });
    await database
        .into(database.catalogMeta)
        .insertOnConflictUpdate(
          CatalogMetaCompanion.insert(
            lang: lang,
            etag: etag,
            datasetVersion: snapshot.datasetVersion,
            mealCount: snapshot.meals.length,
            fetchedAt: fetchedAt.toUtc(),
          ),
        );
  });
}

Future<void> touchCatalogFetchedAt(
  AppDatabase database, {
  required String lang,
  required DateTime fetchedAt,
}) {
  return (database.update(database.catalogMeta)
        ..where((row) => row.lang.equals(lang)))
      .write(CatalogMetaCompanion(fetchedAt: Value(fetchedAt.toUtc())));
}

Future<String?> catalogEtag(AppDatabase database, String lang) async {
  final row = await (database.select(
    database.catalogMeta,
  )..where((table) => table.lang.equals(lang))).getSingleOrNull();
  if (row == null || row.etag.isEmpty) {
    return null;
  }
  return row.etag;
}

Future<void> replaceCuisines(
  AppDatabase database, {
  required String lang,
  required List<({String code, String name})> rows,
}) {
  return database.transaction(() async {
    await (database.delete(
      database.cuisines,
    )..where((row) => row.lang.equals(lang))).go();
    await database.batch((batch) {
      batch.insertAll(database.cuisines, [
        for (final row in rows)
          CuisinesCompanion.insert(lang: lang, code: row.code, name: row.name),
      ]);
    });
  });
}

Future<void> _deleteLanguage(AppDatabase database, String lang) async {
  for (final table in <String>[
    'meal_steps',
    'meal_nutrients',
    'meal_ingredients',
    'meal_allergens',
    'meal_tags',
  ]) {
    await database.customStatement(
      'DELETE FROM $table WHERE lang = ?',
      <Object>[lang],
    );
  }
  await (database.delete(
    database.meals,
  )..where((row) => row.lang.equals(lang))).go();
}
