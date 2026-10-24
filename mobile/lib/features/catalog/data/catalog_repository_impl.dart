import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/db/app_database.dart';
import '../domain/catalog_repository.dart';
import '../domain/meal.dart';
import '../domain/search_normalizer.dart';

const _likeEscape = "ESCAPE ${r"'\'"}";

/// `%` and `_` in a search are literal characters, not LIKE wildcards.
String escapeLike(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

final class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._database, {required this.locale});

  final AppDatabase _database;
  final String Function() locale;

  @override
  Future<MealBrowsePage> browse(MealQuery query) async {
    final lang = locale();
    final status = await _status(lang);
    if (status == null) {
      return const MealBrowsePage(meals: [], cuisines: [], status: null);
    }
    final tags = await _allTags(lang);
    final meals = await _search(lang, query, tags);
    final cuisines = await _cuisines(lang);
    return MealBrowsePage(meals: meals, cuisines: cuisines, status: status);
  }

  @override
  Future<MealDetail?> detail(int mealId) async {
    final lang = locale();
    final row = await _database
        .customSelect(
          '''
SELECT m.name, m.cuisine, m.serving_grams, m.kcal, m.protein_g, m.carb_g,
       m.fat_g, c.name AS cuisine_name, p.stance AS stance
FROM meals m
LEFT JOIN cuisines c ON c.lang = m.lang AND c.code = m.cuisine
LEFT JOIN meal_prefs p ON p.meal_id = m.meal_id
WHERE m.lang = ? AND m.meal_id = ?
''',
          variables: <Variable<Object>>[
            Variable<String>(lang),
            Variable<int>(mealId),
          ],
        )
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    final tags = await _tags(lang, mealId);
    final nutrients = await _nutrients(lang, mealId);
    final ingredients = await _ingredients(lang, mealId);
    final steps = await _steps(lang, mealId);
    final warnings = await _warningCodes(lang, mealId);
    double? sodium;
    double? saturated;
    for (final nutrient in nutrients) {
      if (nutrient.code == 'sodium') {
        sodium = nutrient.perServing;
      } else if (nutrient.code == 'saturated_fat') {
        saturated = nutrient.perServing;
      }
    }
    return MealDetail(
      mealId: mealId,
      name: row.read<String>('name'),
      cuisineName: row.readNullable<String>('cuisine_name'),
      servingGrams: _doubleOf(row.data['serving_grams']),
      kcal: _doubleOf(row.data['kcal']),
      proteinG: _doubleOf(row.data['protein_g']),
      carbG: _doubleOf(row.data['carb_g']),
      fatG: _doubleOf(row.data['fat_g']),
      sodiumPerServing: sodium,
      saturatedFatPerServing: saturated,
      nutrients: nutrients,
      ingredients: ingredients,
      steps: steps,
      iconName: iconForOccasionTags(tags),
      stance: row.readNullable<String>('stance'),
      warningAllergenCodes: warnings,
    );
  }

  @override
  Future<MealFavourites> favourites() async {
    final lang = locale();
    final tags = await _allTags(lang);
    final liked = await _byStance(lang, 'LIKE', tags);
    final disliked = await _byStance(lang, 'DISLIKE', tags);
    return MealFavourites(liked: liked, disliked: disliked);
  }

  Future<CatalogStatus?> _status(String lang) async {
    final row = await (_database.select(
      _database.catalogMeta,
    )..where((table) => table.lang.equals(lang))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return CatalogStatus(mealCount: row.mealCount, fetchedAt: row.fetchedAt);
  }

  Future<List<MealSummary>> _search(
    String lang,
    MealQuery query,
    Map<int, List<String>> tags,
  ) async {
    final normalized = normalizeSearch(query.text);
    final escaped = escapeLike(normalized);
    final started = Stopwatch()..start();
    final rows = await _database
        .customSelect(
          '''
SELECT ${_summaryColumns()}
FROM meals m
LEFT JOIN cuisines c ON c.lang = m.lang AND c.code = m.cuisine
WHERE m.lang = ?
  AND (? = '' OR m.search_key LIKE ? $_likeEscape)
  AND (? IS NULL OR EXISTS (
    SELECT 1 FROM meal_tags slot
    WHERE slot.lang = m.lang AND slot.meal_id = m.meal_id AND slot.tag = ?
  ))
  AND (? IS NULL OR m.cuisine = ?)
  AND (? = 0 OR NOT EXISTS (
    SELECT 1 FROM meal_allergens a
    INNER JOIN user_allergens u ON u.code = a.code
    WHERE a.lang = m.lang AND a.meal_id = m.meal_id
  ))
ORDER BY
  CASE
    WHEN ? = '' THEN 0
    WHEN m.search_key = ? THEN 0
    WHEN m.search_key LIKE ? $_likeEscape THEN 1
    WHEN m.search_key LIKE ? $_likeEscape THEN 2
    ELSE 3
  END,
  m.search_key,
  m.meal_id
''',
          variables: <Variable<Object>>[
            Variable<String>(lang),
            Variable<String>(normalized),
            Variable<String>('%$escaped%'),
            Variable<String>(query.occasionTag),
            Variable<String>(query.occasionTag),
            Variable<String>(query.cuisineCode),
            Variable<String>(query.cuisineCode),
            Variable<int>(query.hideAvoided ? 1 : 0),
            Variable<String>(normalized),
            Variable<String>(normalized),
            Variable<String>('$escaped%'),
            Variable<String>('% $escaped%'),
          ],
        )
        .get();
    if (kDebugMode) {
      debugPrint('catalog search ${started.elapsedMilliseconds}ms');
    }
    return <MealSummary>[for (final row in rows) _summary(row, tags)];
  }

  Future<List<MealSummary>> _byStance(
    String lang,
    String stance,
    Map<int, List<String>> tags,
  ) async {
    final rows = await _database
        .customSelect(
          '''
SELECT ${_summaryColumns()}
FROM meals m
LEFT JOIN cuisines c ON c.lang = m.lang AND c.code = m.cuisine
INNER JOIN meal_prefs p ON p.meal_id = m.meal_id AND p.stance = ?
WHERE m.lang = ?
ORDER BY m.search_key, m.meal_id
''',
          variables: <Variable<Object>>[
            Variable<String>(stance),
            Variable<String>(lang),
          ],
        )
        .get();
    return <MealSummary>[for (final row in rows) _summary(row, tags)];
  }

  Future<Map<int, List<String>>> _allTags(String lang) async {
    final rows = await _database
        .customSelect(
          '''
SELECT meal_id, tag FROM meal_tags
WHERE lang = ?
ORDER BY rowid
''',
          variables: <Variable<Object>>[Variable<String>(lang)],
        )
        .get();
    final tags = <int, List<String>>{};
    for (final row in rows) {
      tags
          .putIfAbsent(row.read<int>('meal_id'), () => <String>[])
          .add(row.read<String>('tag'));
    }
    return tags;
  }

  Future<List<CuisineOption>> _cuisines(String lang) async {
    final rows = await _database
        .customSelect(
          '''
SELECT DISTINCT c.code AS code, c.name AS name
FROM cuisines c
INNER JOIN meals m ON m.lang = c.lang AND m.cuisine = c.code
WHERE c.lang = ?
ORDER BY c.name, c.code
''',
          variables: <Variable<Object>>[Variable<String>(lang)],
        )
        .get();
    return <CuisineOption>[
      for (final row in rows)
        CuisineOption(
          code: row.read<String>('code'),
          name: row.read<String>('name'),
        ),
    ];
  }

  Future<List<String>> _tags(String lang, int mealId) async {
    final rows = await _database
        .customSelect(
          '''
SELECT tag FROM meal_tags
WHERE lang = ? AND meal_id = ?
ORDER BY rowid
''',
          variables: <Variable<Object>>[
            Variable<String>(lang),
            Variable<int>(mealId),
          ],
        )
        .get();
    return <String>[for (final row in rows) row.read<String>('tag')];
  }

  Future<List<NutrientLine>> _nutrients(String lang, int mealId) async {
    final rows = await _database
        .customSelect(
          '''
SELECT code, unit, per_100g, per_serving
FROM meal_nutrients
WHERE lang = ? AND meal_id = ?
''',
          variables: <Variable<Object>>[
            Variable<String>(lang),
            Variable<int>(mealId),
          ],
        )
        .get();
    final byCode = <String, NutrientLine>{};
    for (final row in rows) {
      final code = row.read<String>('code');
      byCode[code] = NutrientLine(
        code: code,
        unit: row.read<String>('unit'),
        per100g: _nullableDouble(row.data['per_100g']),
        perServing: _nullableDouble(row.data['per_serving']),
      );
    }
    return <NutrientLine>[
      for (final code in knownNutrientCodes)
        if (byCode[code] != null) byCode[code]!,
    ];
  }

  Future<List<IngredientLine>> _ingredients(String lang, int mealId) async {
    final rows = await _database
        .customSelect(
          '''
SELECT name, grams_per_serving, is_optional
FROM meal_ingredients
WHERE lang = ? AND meal_id = ?
ORDER BY position
''',
          variables: <Variable<Object>>[
            Variable<String>(lang),
            Variable<int>(mealId),
          ],
        )
        .get();
    return <IngredientLine>[
      for (final row in rows)
        IngredientLine(
          name: row.read<String>('name'),
          gramsPerServing: _doubleOf(row.data['grams_per_serving']),
          isOptional: _boolOf(row.data['is_optional']),
        ),
    ];
  }

  Future<List<String>> _steps(String lang, int mealId) async {
    final rows = await _database
        .customSelect(
          '''
SELECT text FROM meal_steps
WHERE lang = ? AND meal_id = ?
ORDER BY position
''',
          variables: <Variable<Object>>[
            Variable<String>(lang),
            Variable<int>(mealId),
          ],
        )
        .get();
    return <String>[for (final row in rows) row.read<String>('text')];
  }

  Future<List<String>> _warningCodes(String lang, int mealId) async {
    final rows = await _database
        .customSelect(
          '''
SELECT a.code AS code
FROM meal_allergens a
INNER JOIN user_allergens u ON u.code = a.code
WHERE a.lang = ? AND a.meal_id = ?
ORDER BY a.code
''',
          variables: <Variable<Object>>[
            Variable<String>(lang),
            Variable<int>(mealId),
          ],
        )
        .get();
    return <String>[for (final row in rows) row.read<String>('code')];
  }
}

String _summaryColumns() {
  return '''
m.meal_id AS meal_id,
m.name AS name,
m.kcal AS kcal,
m.protein_g AS protein_g,
m.cuisine AS cuisine,
c.name AS cuisine_name,
CASE WHEN EXISTS (
  SELECT 1 FROM meal_prefs p
  WHERE p.meal_id = m.meal_id AND p.stance = 'LIKE'
) THEN 1 ELSE 0 END AS liked,
CASE WHEN EXISTS (
  SELECT 1 FROM meal_allergens a
  INNER JOIN user_allergens u ON u.code = a.code
  WHERE a.lang = m.lang AND a.meal_id = m.meal_id
) THEN 1 ELSE 0 END AS allergen_hit
''';
}

MealSummary _summary(QueryRow row, Map<int, List<String>> tags) {
  final mealTags = tags[row.read<int>('meal_id')] ?? const <String>[];
  return MealSummary(
    mealId: row.read<int>('meal_id'),
    name: row.read<String>('name'),
    kcal: _doubleOf(row.data['kcal']),
    proteinG: _doubleOf(row.data['protein_g']),
    cuisineCode: row.readNullable<String>('cuisine'),
    cuisineName: row.readNullable<String>('cuisine_name'),
    tags: mealTags,
    iconName: iconForOccasionTags(mealTags),
    liked: row.read<int>('liked') == 1,
    allergenWarning: row.read<int>('allergen_hit') == 1,
  );
}

double _doubleOf(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is num) {
    return value.toDouble();
  }
  throw StateError('expected a number');
}

double? _nullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  return _doubleOf(value);
}

bool _boolOf(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is int) {
    return value != 0;
  }
  return false;
}
