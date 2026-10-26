import 'dart:async';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart' as db;
import '../../catalog/domain/search_normalizer.dart';
import '../../plan/data/plan_api.dart';
import '../../plan/domain/plan_dates.dart';
import '../domain/shopping.dart';

class ShoppingRepository {
  ShoppingRepository(this._database, this._api, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final db.AppDatabase _database;
  final PlanApi _api;
  final DateTime Function() _now;

  Future<void> refresh({required DateTime from, required DateTime to}) async {
    final rows = await _api.shopping(from: from, to: to);
    final key = shoppingRangeKey(from, to);
    final previous = await (_database.select(
      _database.shoppingItems,
    )..where((t) => t.rangeKey.equals(key))).get();
    final checked = <int>{
      for (final row in previous)
        if (row.checked) row.ingredientId,
    };
    final sorted = <ShoppingRow>[...rows]
      ..sort(
        (ShoppingRow a, ShoppingRow b) =>
            normalizeSearch(a.name).compareTo(normalizeSearch(b.name)),
      );
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
              checked: checked.contains(row.ingredientId),
            ),
        ]);
      });
    });
  }

  Future<void> setChecked({
    required String rangeKey,
    required int ingredientId,
    required bool checked,
  }) async {
    await (_database.update(_database.shoppingItems)..where(
          (t) =>
              t.rangeKey.equals(rangeKey) & t.ingredientId.equals(ingredientId),
        ))
        .write(db.ShoppingItemsCompanion(checked: Value(checked)));
  }

  Stream<ShoppingSnapshot?> watch({
    required DateTime from,
    required DateTime to,
  }) {
    final key = shoppingRangeKey(from, to);
    final lists = (_database.select(
      _database.shoppingLists,
    )..where((t) => t.rangeKey.equals(key))).watch();
    final items = (_database.select(
      _database.shoppingItems,
    )..where((t) => t.rangeKey.equals(key))).watch();
    return Stream<Object?>.multi((MultiStreamController<Object?> listener) {
      final subscriptions = <StreamSubscription<Object?>>[
        lists.listen((_) => listener.add(null), onError: listener.addError),
        items.listen((_) => listener.add(null), onError: listener.addError),
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
      final mapped =
          <ShoppingRow>[
            for (final row in rows)
              if (!isTapWater(row.name))
                ShoppingRow(
                  ingredientId: row.ingredientId,
                  name: row.name,
                  grams: row.grams,
                  meals: row.meals,
                  checked: row.checked,
                ),
          ]..sort(
            (ShoppingRow a, ShoppingRow b) =>
                normalizeSearch(a.name).compareTo(normalizeSearch(b.name)),
          );
      return ShoppingSnapshot(
        rangeKey: key,
        dateFrom: isoDate(dateOnly(from)),
        dateTo: isoDate(dateOnly(to)),
        items: mapped,
      );
    });
  }
}
