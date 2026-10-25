import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/db/app_database.dart';
import 'package:nutriguide/features/plan/data/plan_api.dart';
import 'package:nutriguide/features/shopping/data/shopping_repository.dart';
import 'package:nutriguide/features/shopping/domain/shopping.dart';

void main() {
  test('refresh keeps checked items that are still present', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final api = _ShopApi(<ShoppingRow>[
      const ShoppingRow(
        ingredientId: 2,
        name: 'بصل',
        grams: 1200,
        meals: 3,
        checked: false,
      ),
      const ShoppingRow(
        ingredientId: 1,
        name: 'طماطم',
        grams: 346,
        meals: 2,
        checked: false,
      ),
    ]);
    final repository = ShoppingRepository(
      database,
      api,
      now: () => DateTime.utc(2026, 10, 24),
    );
    final from = DateTime(2026, 10, 24);
    final to = DateTime(2026, 10, 30);
    await repository.refresh(from: from, to: to);
    final key = (await repository.watch(from: from, to: to).first)!.rangeKey;
    await repository.setChecked(rangeKey: key, ingredientId: 1, checked: true);
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
