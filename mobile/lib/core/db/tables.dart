import 'package:drift/drift.dart';

/// One row per language of the offline catalog.
class CatalogMeta extends Table {
  TextColumn get lang => text()();

  TextColumn get etag => text()();

  TextColumn get datasetVersion => text()();

  IntColumn get mealCount => integer()();

  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {lang};
}

@TableIndex(name: 'meals_lang_search_key', columns: {#lang, #searchKey})
class Meals extends Table {
  TextColumn get lang => text()();

  IntColumn get mealId => integer()();

  TextColumn get name => text()();

  TextColumn get searchKey => text()();

  TextColumn get cuisine => text().nullable()();

  TextColumn get dishForm => text().nullable()();

  RealColumn get servingGrams => real()();

  IntColumn get servings => integer()();

  RealColumn get totalGrams => real()();

  RealColumn get kcal => real()();

  RealColumn get proteinG => real()();

  RealColumn get carbG => real()();

  RealColumn get fatG => real()();

  TextColumn get source => text()();

  TextColumn get datasetVersion => text()();

  @override
  Set<Column<Object>> get primaryKey => {lang, mealId};
}

class MealTags extends Table {
  TextColumn get lang => text()();

  IntColumn get mealId => integer()();

  TextColumn get tag => text()();

  @override
  Set<Column<Object>> get primaryKey => {lang, mealId, tag};

  @override
  List<String> get customConstraints => const <String>[
    'FOREIGN KEY(lang, meal_id) REFERENCES meals(lang, meal_id) ON DELETE CASCADE',
  ];
}

class MealAllergens extends Table {
  TextColumn get lang => text()();

  IntColumn get mealId => integer()();

  TextColumn get code => text()();

  @override
  Set<Column<Object>> get primaryKey => {lang, mealId, code};

  @override
  List<String> get customConstraints => const <String>[
    'FOREIGN KEY(lang, meal_id) REFERENCES meals(lang, meal_id) ON DELETE CASCADE',
  ];
}

class MealIngredients extends Table {
  TextColumn get lang => text()();

  IntColumn get mealId => integer()();

  IntColumn get position => integer()();

  IntColumn get ingredientId => integer()();

  TextColumn get name => text()();

  RealColumn get gramsPerServing => real()();

  BoolColumn get isOptional => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {lang, mealId, position};

  @override
  List<String> get customConstraints => const <String>[
    'FOREIGN KEY(lang, meal_id) REFERENCES meals(lang, meal_id) ON DELETE CASCADE',
  ];
}

class MealNutrients extends Table {
  TextColumn get lang => text()();

  IntColumn get mealId => integer()();

  TextColumn get code => text()();

  TextColumn get unit => text()();

  RealColumn get per100g => real().named('per_100g').nullable()();

  RealColumn get perServing => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {lang, mealId, code};

  @override
  List<String> get customConstraints => const <String>[
    'FOREIGN KEY(lang, meal_id) REFERENCES meals(lang, meal_id) ON DELETE CASCADE',
  ];
}

class MealSteps extends Table {
  TextColumn get lang => text()();

  IntColumn get mealId => integer()();

  IntColumn get position => integer()();

  TextColumn get stepText => text().named('text')();

  @override
  Set<Column<Object>> get primaryKey => {lang, mealId, position};

  @override
  List<String> get customConstraints => const <String>[
    'FOREIGN KEY(lang, meal_id) REFERENCES meals(lang, meal_id) ON DELETE CASCADE',
  ];
}

class Cuisines extends Table {
  TextColumn get lang => text()();

  TextColumn get code => text()();

  TextColumn get name => text()();

  @override
  Set<Column<Object>> get primaryKey => {lang, code};
}

/// Personal. Cleared on logout and when another account signs in.
class LocalMealPrefs extends Table {
  @override
  String get tableName => 'meal_prefs';

  IntColumn get mealId => integer()();

  TextColumn get stance => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mealId};
}

/// Personal. Cleared on logout and when another account signs in.
class UserAllergens extends Table {
  TextColumn get code => text()();

  TextColumn get severity => text()();

  @override
  Set<Column<Object>> get primaryKey => {code};
}
