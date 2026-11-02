import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/db/app_database.dart';
import 'package:nutriguide/features/plan/data/plan_api.dart';
import 'package:nutriguide/features/shopping/data/shopping_repository.dart';
import 'package:nutriguide/features/shopping/domain/shopping.dart';

const _onion = ShoppingRow(
  ingredientId: 2,
  name: 'بصل',
  grams: 1200,
  meals: 3,
  checked: false,
  categoryCode: '1100',
  category: 'الخضروات',
);
const _tomato = ShoppingRow(
  ingredientId: 1,
  name: 'طماطم',
  grams: 346,
  meals: 2,
  checked: false,
  categoryCode: '1100',
  category: 'الخضروات',
);
const _milk = ShoppingRow(
  ingredientId: 5,
  name: 'حليب',
  grams: 500,
  meals: 2,
  checked: false,
  categoryCode: '0100',
  category: 'الألبان والبيض',
);

void main() {
  test('refresh keeps checked items that are still present', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final api = _ShopApi(<ShoppingRow>[_onion, _tomato]);
    final repository = ShoppingRepository(
      database,
      api,
      now: () => DateTime.utc(2026, 10, 24),
    );
    final from = DateTime(2026, 10, 24);
    final to = DateTime(2026, 10, 30);
    await repository.refresh(from: from, to: to);
    final key = (await repository.watch(from: from, to: to).first)!.rangeKey;
    await repository.setChecked(weekKey: key, ingredientId: 1, checked: true);
    await repository.refresh(from: from, to: to);
    final snapshot = await repository.watch(from: from, to: to).first;
    final tomato = snapshot!.items.firstWhere(
      (ShoppingRow row) => row.ingredientId == 1,
    );
    final onion = snapshot.items.firstWhere(
      (ShoppingRow row) => row.ingredientId == 2,
    );
    expect(tomato.checked, isTrue);
    expect(onion.checked, isFalse);
    expect(tomato.categoryCode, '1100');
    expect(tomato.category, 'الخضروات');
  });

  test('a tick is shared by the week list and the today list', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final api = _ShopApi(<ShoppingRow>[_onion, _tomato, _milk]);
    final repository = ShoppingRepository(database, api);
    final from = DateTime(2026, 10, 24);
    final to = DateTime(2026, 10, 30);
    final weekKey = '2026-10-24_2026-10-30';
    await repository.refresh(from: from, to: to);
    await repository.refresh(from: from, to: from);
    await repository.setChecked(
      weekKey: weekKey,
      ingredientId: 5,
      checked: true,
    );
    final today = await repository
        .watch(from: from, to: from, weekKey: weekKey)
        .first;
    expect(
      today!.items
          .singleWhere((ShoppingRow row) => row.ingredientId == 5)
          .checked,
      isTrue,
    );
    // Rows come back in food group order, then by name.
    expect(
      today.items.map((ShoppingRow row) => row.ingredientId).toList(),
      <int>[5, 2, 1],
    );
    await repository.setChecked(
      weekKey: weekKey,
      ingredientId: 5,
      checked: false,
    );
    final week = await repository.watch(from: from, to: to).first;
    expect(week!.checkedCount, 0);
  });

  test('groups follow the food group code and missing codes fall back', () {
    final groups = groupShopping(<ShoppingRow>[_onion, _tomato, _milk]);
    expect(groups.map((ShoppingGroup group) => group.code).toList(), <String>[
      '0100',
      '1100',
    ]);
    expect(groups.last.name, 'الخضروات');
    expect(groups.last.rows, hasLength(2));
    const old = ShoppingRow(
      ingredientId: 9,
      name: 'ملح',
      grams: 3,
      meals: 1,
      checked: false,
    );
    final fallback = groupShopping(const <ShoppingRow>[old]);
    expect(fallback, hasLength(1));
    expect(fallback.single.code, isEmpty);
    final mixed = groupShopping(<ShoppingRow>[old, _milk]);
    expect(mixed.last.code, isEmpty);
  });

  test('every catalog food group has its own emoji', () {
    const codes = <String>[
      '0100', '0200', '0400', '0500', '0800', '0900', '1100', '1200', //
      '1300', '1400', '1500', '1600', '1700', '1800', '1900', '2000', '2500',
    ];
    for (final code in codes) {
      expect(categoryEmoji(code), isNot('shopping-cart'), reason: code);
    }
    expect(categoryEmoji('1100'), 'leafy-green');
    expect(categoryEmoji('1500'), 'fish');
    expect(categoryEmoji(''), 'shopping-cart');
  });

  test('the current meal is the open window, else the next one', () {
    int minutes(String hhmm) {
      final parts = hhmm.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    const windows = <String, ({String start, String end})>{
      'BREAKFAST': (start: '07:00', end: '10:00'),
      'LUNCH': (start: '12:00', end: '15:00'),
      'DINNER': (start: '18:00', end: '21:00'),
    };
    String? pick(int now, {List<String>? slots}) => pickCurrentMeal<String>(
      items: slots ?? <String>['DINNER', 'BREAKFAST', 'LUNCH', 'EXTRA'],
      window: (String slot) => windows[slot],
      nowMinutes: now,
      minutes: minutes,
    );
    expect(pick(8 * 60), 'BREAKFAST');
    expect(pick(11 * 60), 'LUNCH');
    expect(pick(15 * 60 + 1), 'DINNER');
    expect(pick(22 * 60), isNull);
    expect(pick(8 * 60, slots: <String>['EXTRA']), isNull);
  });

  test('current meal grams scale by the item and skip optional and water', () {
    final rows = mealShoppingRows(
      ingredients:
          const <
            ({
              int ingredientId,
              String name,
              double gramsPerServing,
              bool isOptional,
            })
          >[
            (
              ingredientId: 1,
              name: 'طماطم',
              gramsPerServing: 100,
              isOptional: false,
            ),
            (
              ingredientId: 7,
              name: 'ماء',
              gramsPerServing: 200,
              isOptional: false,
            ),
            (
              ingredientId: 8,
              name: 'بقدونس',
              gramsPerServing: 5,
              isOptional: true,
            ),
            (
              ingredientId: 1,
              name: 'طماطم',
              gramsPerServing: 20,
              isOptional: false,
            ),
            (
              ingredientId: 5,
              name: 'حليب',
              gramsPerServing: 40,
              isOptional: false,
            ),
          ],
      itemGrams: 450,
      servingGrams: 300,
      categories: const <int, ({String code, String name})>{
        5: (code: '0100', name: 'الألبان والبيض'),
      },
      checked: const <int>{5},
    );
    expect(rows.map((ShoppingRow row) => row.ingredientId), <int>[1, 5]);
    expect(rows.first.grams, 180);
    expect(rows.first.meals, 1);
    expect(rows.first.categoryCode, isEmpty);
    expect(rows.last.grams, 60);
    expect(rows.last.checked, isTrue);
    expect(rows.last.categoryCode, '0100');
  });

  test('grams under 1000 round to 10 and the rest become kilograms', () {
    final grams = shoppingQuantity(346);
    expect(grams.approximate, isTrue);
    expect(grams.kilograms, isFalse);
    expect(grams.amount, 350);
    final kilos = shoppingQuantity(1200);
    expect(kilos.kilograms, isTrue);
    expect(kilos.amount, 1.2);
    expect(shoppingQuantity(0.6).amount, 1);
    expect(shoppingQuantity(3.2).amount, 3);
    expect(shoppingQuantity(6).amount, 10);
  });

  test('share text excludes checked items', () {
    const items = <ShoppingRow>[
      ShoppingRow(
        ingredientId: 1,
        name: 'طماطم',
        grams: 350,
        meals: 2,
        checked: true,
      ),
      ShoppingRow(
        ingredientId: 2,
        name: 'بصل',
        grams: 1200,
        meals: 1,
        checked: false,
      ),
    ];
    final text = shoppingShareText(
      header: 'قائمة مشترياتي (2026-10-24 – 2026-10-30)',
      items: items,
      quantity: (ShoppingRow row) =>
          row.ingredientId == 2 ? '1.2 كغ' : '≈ 350 غ',
    );
    expect(text, contains('بصل'));
    expect(text, isNot(contains('طماطم')));
  });

  test('share text puts unchecked items under their food group', () {
    final text = shoppingShareText(
      header: 'قائمتي',
      items: <ShoppingRow>[_onion, _milk, _tomato.withChecked(true)],
      quantity: (ShoppingRow row) => '${row.grams}',
      groupName: (ShoppingGroup group) => group.name,
    );
    expect(
      text,
      'قائمتي\n\nالألبان والبيض\n- حليب: 500.0\n\nالخضروات\n- بصل: 1200.0',
    );
  });
}

class _ShopApi extends PlanApi {
  _ShopApi(this.rows) : super(Dio());

  final List<ShoppingRow> rows;

  @override
  Future<List<ShoppingRow>> shopping({
    required DateTime from,
    required DateTime to,
  }) async {
    return rows;
  }
}
