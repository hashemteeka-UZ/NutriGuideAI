import 'dart:async';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart' as db;
import '../../catalog/domain/search_normalizer.dart';
import '../../plan/data/plan_api.dart';
import '../../plan/domain/plan_dates.dart';
import '../domain/shopping.dart';

/// One plan item's ingredients from the local catalog.
typedef MealIngredientRows = ({
  double servingGrams,
  List<
    ({int ingredientId, String name, double gramsPerServing, bool isOptional})
  >
  ingredients,
});

class ShoppingRepository {
  ShoppingRepository(this._database, this._api, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final db.AppDatabase _database;
  final PlanApi _api;
  final DateTime Function() _now;

  /// Fetches one range and replaces its cached rows. Ticks are kept apart in
  /// `shopping_checks`, so a refresh never clears them.
  Future<void> refresh({required DateTime from, required DateTime to}) async {
    final rows = await _api.shopping(from: from, to: to);
    final key = shoppingRangeKey(from, to);
    final sorted = <ShoppingRow>[...rows]..sort(compareShoppingRows);
    await _database.transaction(() async {
      await _database
          .into(_database.shoppingLists)
          .insertOnConflictUpdate(
            db.ShoppingListsCompanion.insert(
              rangeKey: key,
              fetchedAt: _now().toUtc(),
            ),
          );
      await (_database.delete(
        _database.shoppingItems,
      )..where((t) => t.rangeKey.equals(key))).go();
      await _database.batch((Batch batch) {
        batch.insertAll(_database.shoppingItems, <db.ShoppingItemsCompanion>[
          for (final row in sorted)
            db.ShoppingItemsCompanion.insert(
              rangeKey: key,
              ingredientId: row.ingredientId,
              name: row.name,
              grams: row.grams,
              meals: row.meals,
              checked: false,
              categoryCode: Value(row.categoryCode),
              category: Value(row.category),
            ),
        ]);
      });
    });
  }

  /// Ticks one ingredient as bought (or not) for the whole week range.
  Future<void> setChecked({
    required String weekKey,
    required int ingredientId,
    required bool checked,
  }) async {
    if (checked) {
      await _database
          .into(_database.shoppingChecks)
          .insertOnConflictUpdate(
            db.ShoppingChecksCompanion.insert(
              weekKey: weekKey,
              ingredientId: ingredientId,
              checkedAt: _now().toUtc(),
            ),
          );
      return;
    }
    await (_database.delete(_database.shoppingChecks)..where(
          (t) =>
              t.weekKey.equals(weekKey) & t.ingredientId.equals(ingredientId),
        ))
        .go();
  }

  Stream<Set<int>> watchChecks(String weekKey) {
    return (_database.select(
      _database.shoppingChecks,
    )..where((t) => t.weekKey.equals(weekKey))).watch().map(
      (List<db.ShoppingCheck> rows) => <int>{
        for (final row in rows) row.ingredientId,
      },
    );
  }

  /// The cached list for one range with the ticks of [weekKey] (the range
  /// itself when not given).
  Stream<ShoppingSnapshot?> watch({
    required DateTime from,
    required DateTime to,
    String? weekKey,
  }) {
    final key = shoppingRangeKey(from, to);
    final checksKey = weekKey ?? key;
    final lists = (_database.select(
      _database.shoppingLists,
    )..where((t) => t.rangeKey.equals(key))).watch();
    final items = (_database.select(
      _database.shoppingItems,
    )..where((t) => t.rangeKey.equals(key))).watch();
    final checks = watchChecks(checksKey);
    return Stream<Object?>.multi((MultiStreamController<Object?> listener) {
      final subscriptions = <StreamSubscription<Object?>>[
        lists.listen((_) => listener.add(null), onError: listener.addError),
        items.listen((_) => listener.add(null), onError: listener.addError),
        checks.listen((_) => listener.add(null), onError: listener.addError),
      ];
      listener.onCancel = () {
        for (final subscription in subscriptions) {
          unawaited(subscription.cancel());
        }
      };
    }).asyncMap((Object? _) async {
      final header = await (_database.select(
        _database.shoppingLists,
      )..where((t) => t.rangeKey.equals(key))).getSingleOrNull();
      if (header == null) {
        return null;
      }
      final rows = await (_database.select(
        _database.shoppingItems,
      )..where((t) => t.rangeKey.equals(key))).get();
      final ticked = await (_database.select(
        _database.shoppingChecks,
      )..where((t) => t.weekKey.equals(checksKey))).get();
      final checked = <int>{for (final row in ticked) row.ingredientId};
      final mapped = <ShoppingRow>[
        for (final row in rows)
          if (!isTapWater(row.name))
            ShoppingRow(
              ingredientId: row.ingredientId,
              name: row.name,
              grams: row.grams,
              meals: row.meals,
              checked: checked.contains(row.ingredientId),
              categoryCode: row.categoryCode,
              category: row.category,
            ),
      ]..sort(compareShoppingRows);
      return ShoppingSnapshot(
        rangeKey: key,
        dateFrom: isoDate(dateOnly(from)),
        dateTo: isoDate(dateOnly(to)),
        items: mapped,
      );
    });
  }

  /// Ingredients of one catalog meal in [lang], or null when the meal is not
  /// in the local catalog.
  Future<MealIngredientRows?> mealIngredients({
    required int mealId,
    required String lang,
  }) async {
    final meal =
        await (_database.select(_database.meals)
              ..where((t) => t.lang.equals(lang) & t.mealId.equals(mealId)))
            .getSingleOrNull();
    if (meal == null) {
      return null;
    }
    final lines =
        await (_database.select(_database.mealIngredients)
              ..where((t) => t.lang.equals(lang) & t.mealId.equals(mealId))
              ..orderBy(<OrderClauseGenerator<db.$MealIngredientsTable>>[
                (t) => OrderingTerm(expression: t.position),
              ]))
            .get();
    return (
      servingGrams: meal.servingGrams,
      ingredients:
          <
            ({
              int ingredientId,
              String name,
              double gramsPerServing,
              bool isOptional,
            })
          >[
            for (final line in lines)
              (
                ingredientId: line.ingredientId,
                name: line.name,
                gramsPerServing: line.gramsPerServing,
                isOptional: line.isOptional,
              ),
          ],
    );
  }
}

/// Food group code first (rows without one last), then the name.
int compareShoppingRows(ShoppingRow a, ShoppingRow b) {
  if (a.categoryCode.isEmpty != b.categoryCode.isEmpty) {
    return a.categoryCode.isEmpty ? 1 : -1;
  }
  final byCode = a.categoryCode.compareTo(b.categoryCode);
  if (byCode != 0) {
    return byCode;
  }
  return normalizeSearch(a.name).compareTo(normalizeSearch(b.name));
}
