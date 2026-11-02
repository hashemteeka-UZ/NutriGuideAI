import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/locale/locale_controller.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/domain/meal_timing.dart';
import '../../plan/domain/plan.dart';
import '../../plan/domain/plan_dates.dart';
import '../domain/shopping.dart';
import 'shopping_repository.dart';

abstract interface class TextShare {
  Future<void> share(String text);
}

class SharePlusTextShare implements TextShare {
  const SharePlusTextShare();

  @override
  Future<void> share(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }
}

final textShareProvider = Provider<TextShare>(
  (ref) => const SharePlusTextShare(),
);

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(planApiProvider),
    now: ref.watch(planClockProvider),
  );
});

/// The week range whose ticks every scope shares.
final shoppingWeekKeyProvider = Provider<String>((ref) {
  final dates = weekDates(ref.watch(planClockProvider)());
  return shoppingRangeKey(dates.first, dates.last);
});

class ShoppingScopeController extends Notifier<ShoppingScope> {
  @override
  ShoppingScope build() => ShoppingScope.plan;

  void select(ShoppingScope scope) => state = scope;
}

final shoppingScopeProvider =
    NotifierProvider<ShoppingScopeController, ShoppingScope>(
      ShoppingScopeController.new,
    );

final shoppingChecksProvider = StreamProvider<Set<int>>((ref) {
  return ref
      .watch(shoppingRepositoryProvider)
      .watchChecks(ref.watch(shoppingWeekKeyProvider));
});

/// The whole plan week (the list as before P2b).
final shoppingProvider = StreamProvider<ShoppingSnapshot?>((ref) {
  final dates = weekDates(ref.watch(planClockProvider)());
  return ref
      .watch(shoppingRepositoryProvider)
      .watch(from: dates.first, to: dates.last);
});

/// Today only: `GET /shopping-list?from=today&to=today`, week ticks.
final todayShoppingProvider = StreamProvider<ShoppingSnapshot?>((ref) {
  final today = dateOnly(ref.watch(planClockProvider)());
  return ref
      .watch(shoppingRepositoryProvider)
      .watch(
        from: today,
        to: today,
        weekKey: ref.watch(shoppingWeekKeyProvider),
      );
});

class CurrentMealShopping {
  const CurrentMealShopping({
    required this.item,
    required this.now,
    required this.rows,
    this.start,
    this.end,
  });

  final PlanItem item;

  /// True when the item's window contains the current time.
  final bool now;
  final String? start;
  final String? end;
  final List<ShoppingRow> rows;
}

/// The plan item to shop for now, computed on the phone from the local
/// catalog: null when today has no plan or no meal now or later today.
final currentMealShoppingProvider = FutureProvider<CurrentMealShopping?>((
  ref,
) async {
  ref.watch(localeProvider);
  final plan = await ref.watch(todayPlanProvider.future);
  if (plan == null || plan.items.isEmpty) {
    return null;
  }
  final windows = await ref.watch(todayWindowsProvider.future);
  final checked = await ref.watch(shoppingChecksProvider.future);
  final week = await ref.watch(shoppingProvider.future);
  final spans = <String, MealWindowSpan>{
    for (final window in windows) window.slot: window,
  };
  final clock = ref.watch(planClockProvider)();
  final nowMinutes = clock.hour * 60 + clock.minute;
  final item = pickCurrentMeal<PlanItem>(
    items: plan.items,
    window: (PlanItem item) {
      final span = spans[item.slot];
      return span == null ? null : (start: span.start, end: span.end);
    },
    nowMinutes: nowMinutes,
    minutes: clockMinutes,
  );
  if (item == null) {
    return null;
  }
  final ingredients = await ref
      .watch(shoppingRepositoryProvider)
      .mealIngredients(
        mealId: item.mealId,
        lang: ref.read(localeCodeProvider).code,
      );
  final categories = <int, ({String code, String name})>{
    for (final row in week?.items ?? const <ShoppingRow>[])
      row.ingredientId: (code: row.categoryCode, name: row.category),
  };
  final rows = ingredients == null
      ? <ShoppingRow>[]
      : mealShoppingRows(
          ingredients: ingredients.ingredients,
          itemGrams: item.grams,
          servingGrams: ingredients.servingGrams,
          categories: categories,
          checked: checked,
        );
  final span = spans[item.slot];
  final start = span == null ? null : clockMinutes(span.start);
  return CurrentMealShopping(
    item: item,
    now: start != null && start <= nowMinutes,
    start: span?.start,
    end: span?.end,
    rows: rows..sort(compareShoppingRows),
  );
});
