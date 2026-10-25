import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/locale/locale_controller.dart';
import '../domain/meal.dart';

/// Five meals with the lowest kcal per serving, skipping drinks (tag
/// `beverage`) and the user's allergens. Ties break on meal id so the list
/// does not change between launches.
Future<List<SuggestedMeal>> healthyMeals(
  AppDatabase database,
  String lang,
) async {
  final rows = await database
      .customSelect(
        '''
SELECT m.meal_id, m.name, m.kcal
FROM meals m
WHERE m.lang = ?
  AND NOT EXISTS (
    SELECT 1 FROM meal_allergens a
    JOIN user_allergens u ON u.code = a.code
    WHERE a.lang = m.lang AND a.meal_id = m.meal_id
  )
  AND NOT EXISTS (
    SELECT 1 FROM meal_tags t
    WHERE t.lang = m.lang AND t.meal_id = m.meal_id AND t.tag = 'beverage'
  )
ORDER BY m.kcal ASC, m.meal_id ASC
LIMIT 5
''',
        variables: <Variable<Object>>[Variable<String>(lang)],
      )
      .get();
  if (rows.isEmpty) {
    return const <SuggestedMeal>[];
  }
  final ids = <int>[for (final row in rows) row.read<int>('meal_id')];
  final tags = await (database.select(
    database.mealTags,
  )..where((t) => t.lang.equals(lang) & t.mealId.isIn(ids))).get();
  final byMeal = <int, List<String>>{};
  for (final tag in tags) {
    byMeal.putIfAbsent(tag.mealId, () => <String>[]).add(tag.tag);
  }
  return <SuggestedMeal>[
    for (final row in rows)
      SuggestedMeal(
        mealId: row.read<int>('meal_id'),
        name: row.read<String>('name'),
        kcal: (row.data['kcal'] as num).toDouble(),
        iconName: iconForOccasionTags(
          byMeal[row.read<int>('meal_id')] ?? const <String>[],
        ),
      ),
  ];
}

Stream<int> watchLikeCount(AppDatabase database) {
  final query = database.select(database.localMealPrefs)
    ..where((t) => t.stance.equals('LIKE'));
  return query.watch().map((List<LocalMealPref> rows) => rows.length);
}

Future<int> catalogMealCount(AppDatabase database, String lang) async {
  final row = await (database.select(
    database.catalogMeta,
  )..where((t) => t.lang.equals(lang))).getSingleOrNull();
  return row?.mealCount ?? 0;
}

final catalogMealCountProvider = FutureProvider<int>((ref) {
  final lang = ref.watch(localeProvider).languageCode;
  return catalogMealCount(ref.watch(appDatabaseProvider), lang);
});

final mealDislikeProvider = FutureProvider<bool>((ref) {
  return anyMealDislike(ref.watch(appDatabaseProvider));
});

final healthyMealsProvider = FutureProvider<List<SuggestedMeal>>((ref) {
  final lang = ref.watch(localeProvider).languageCode;
  return healthyMeals(ref.watch(appDatabaseProvider), lang);
});

final likeCountProvider = StreamProvider<int>((ref) {
  return watchLikeCount(ref.watch(appDatabaseProvider));
});

Future<bool> anyMealDislike(AppDatabase database) async {
  final row = await (database.select(
    database.localMealPrefs,
  )..where((t) => t.stance.equals('DISLIKE'))).get();
  return row.isNotEmpty;
}
