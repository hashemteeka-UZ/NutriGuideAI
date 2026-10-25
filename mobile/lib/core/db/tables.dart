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

/// Personal. One stored plan per local date.
class Plans extends Table {
  TextColumn get planDate => text()();

  IntColumn get planId => integer()();

  TextColumn get algorithmVersion => text()();

  DateTimeColumn get createdAt => dateTime()();

  IntColumn get kcal => integer()();

  RealColumn get proteinG => real()();

  RealColumn get carbG => real()();

  RealColumn get fatG => real()();

  IntColumn get fiberG => integer()();

  RealColumn get totalsKcal => real().nullable()();

  RealColumn get totalsProteinG => real().nullable()();

  RealColumn get totalsCarbG => real().nullable()();

  RealColumn get totalsFatG => real().nullable()();

  RealColumn get totalsFiberG => real().nullable()();

  RealColumn get totalsSaturatedFatG => real().nullable()();

  RealColumn get totalsSodiumMg => real().nullable()();

  RealColumn get totalsSugarsG => real().nullable()();

  BoolColumn get kcalWithin10pct => boolean()();

  TextColumn get solverStatus => text().nullable()();

  BoolColumn get kcalRelaxed => boolean().nullable()();

  RealColumn get solveSeconds => real().nullable()();

  IntColumn get candidateMeals => integer().nullable()();

  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {planDate};
}

/// Personal. Items of a stored plan. Deleted with the plan.
class PlanItems extends Table {
  IntColumn get planItemId => integer()();

  TextColumn get planDate =>
      text().references(Plans, #planDate, onDelete: KeyAction.cascade)();

  IntColumn get position => integer()();

  TextColumn get slot => text()();

  IntColumn get mealId => integer()();

  TextColumn get mealName => text()();

  RealColumn get servingsMultiplier => real()();

  RealColumn get grams => real()();

  RealColumn get kcal => real()();

  RealColumn get proteinG => real()();

  RealColumn get carbG => real()();

  RealColumn get fatG => real()();

  TextColumn get reasonCodes => text()();

  BoolColumn get wasSwapped => boolean()();

  BoolColumn get logged => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {planItemId};
}

/// Personal. Nutrients under the plan minimum. Deleted with the plan.
class PlanUnmetMinimums extends Table {
  TextColumn get planDate =>
      text().references(Plans, #planDate, onDelete: KeyAction.cascade)();

  TextColumn get nutrient => text()();

  RealColumn get minimum => real()();

  RealColumn get total => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {planDate, nutrient};
}

/// Personal. Meal windows for one local date, from the day view.
class MealWindows extends Table {
  TextColumn get windowDate => text()();

  TextColumn get slot => text()();

  TextColumn get start => text()();

  TextColumn get end => text()();

  @override
  Set<Column<Object>> get primaryKey => {windowDate, slot};
}

/// Personal. Adherence and water totals shown on Today.
class DaySummaries extends Table {
  TextColumn get summaryDate => text()();

  RealColumn get targetKcal => real().nullable()();

  RealColumn get kcal => real().nullable()();

  RealColumn get proteinG => real().nullable()();

  RealColumn get carbG => real().nullable()();

  RealColumn get fatG => real().nullable()();

  IntColumn get planItemsTotal => integer()();

  IntColumn get planItemsConsumed => integer()();

  TextColumn get status => text().nullable()();

  IntColumn get totalMl => integer()();

  IntColumn get goalMl => integer().nullable()();

  BoolColumn get requiresClinician => boolean()();

  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {summaryDate};
}

/// Personal. One cached shopping list per inclusive date range.
class ShoppingLists extends Table {
  TextColumn get rangeKey => text()();

  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {rangeKey};
}

/// Personal. Operations waiting to be sent with `POST /sync/batch`, in [seq]
/// order. A row keeps its [opId] and payload for every retry.
class Outbox extends Table {
  @override
  String get tableName => 'outbox';

  TextColumn get opId => text()();

  IntColumn get seq => integer().unique()();

  TextColumn get opType => text()();

  TextColumn get payloadJson => text()();

  TextColumn get clientUuid => text().nullable()();

  TextColumn get entityRef => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  TextColumn get lastErrorCode => text().nullable()();

  /// PENDING or REJECTED.
  TextColumn get state => text()();

  @override
  Set<Column<Object>> get primaryKey => {opId};
}

/// Personal. What the user ate, keyed by the id the phone generated. Server
/// nutrients stay null until the server has the log.
class ConsumptionLogs extends Table {
  TextColumn get clientUuid => text()();

  IntColumn get serverLogId => integer().nullable().unique()();

  TextColumn get kind => text()();

  IntColumn get planItemId => integer().nullable()();

  IntColumn get mealId => integer().nullable()();

  TextColumn get logDate => text()();

  TextColumn get slot => text().nullable()();

  RealColumn get servingsConsumed => real().nullable()();

  DateTimeColumn get consumedAt => dateTime()();

  TextColumn get name => text().nullable()();

  RealColumn get kcal => real().nullable()();

  RealColumn get proteinG => real().nullable()();

  RealColumn get carbG => real().nullable()();

  RealColumn get fatG => real().nullable()();

  /// PENDING, CONFIRMED, REJECTED or DELETING.
  TextColumn get state => text()();

  @override
  Set<Column<Object>> get primaryKey => {clientUuid};
}

/// Personal. Checked state stays on the phone for ingredients still in the list.
class ShoppingItems extends Table {
  TextColumn get rangeKey => text().references(
    ShoppingLists,
    #rangeKey,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get ingredientId => integer()();

  TextColumn get name => text()();

  RealColumn get grams => real()();

  IntColumn get meals => integer()();

  BoolColumn get checked => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {rangeKey, ingredientId};
}
