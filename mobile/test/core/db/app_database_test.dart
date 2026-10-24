import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/db/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('opens an in-memory database at schema version 2', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    expect(database.schemaVersion, 2);
    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .map((row) => row.read<String>('name'))
        .get();
    expect(tables, <String>[
      'catalog_meta',
      'cuisines',
      'meal_allergens',
      'meal_ingredients',
      'meal_nutrients',
      'meal_prefs',
      'meal_steps',
      'meal_tags',
      'meals',
      'user_allergens',
    ]);
  });
}
