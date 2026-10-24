import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/l10n/app_localizations.dart';
import 'package:nutriguide/core/theme/app_theme.dart';
import 'package:nutriguide/features/catalog/data/catalog_providers.dart';
import 'package:nutriguide/features/catalog/data/catalog_sync.dart';
import 'package:nutriguide/features/catalog/domain/catalog_repository.dart';
import 'package:nutriguide/features/catalog/domain/meal.dart';
import 'package:nutriguide/features/catalog/presentation/favourites_screen.dart';
import 'package:nutriguide/features/catalog/presentation/meal_detail_screen.dart';
import 'package:nutriguide/features/catalog/presentation/meals_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeCatalog catalog;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    catalog = _FakeCatalog();
  });

  testWidgets('browse lists meals and filters the slot', (tester) async {
    await _pump(tester, catalog, const MealsScreen());
    expect(find.byKey(const Key('meal-card-1')), findsOneWidget);
    expect(find.byKey(const Key('meal-card-2')), findsOneWidget);
    expect(find.byKey(const Key('meal-card-3')), findsNothing);
    expect(find.byKey(const Key('meals-footer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('meals-slot-breakfast_suitable')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('meal-card-1')), findsOneWidget);
    expect(find.byKey(const Key('meal-card-2')), findsNothing);
    expect(catalog.last?.occasionTag, breakfastTag);
  });

  testWidgets('search updates the list', (tester) async {
    await _pump(tester, catalog, const MealsScreen());
    await tester.enterText(find.byKey(const Key('meals-search')), 'غداء');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('meal-card-2')), findsOneWidget);
    expect(find.byKey(const Key('meal-card-1')), findsNothing);
  });

  testWidgets('details show preparation steps', (tester) async {
    catalog.detailMeal = _detail(steps: const <String>['اخلط']);
    await _pump(tester, catalog, const MealDetailScreen(mealId: 1));
    expect(find.text('اخلط', skipOffstage: false), findsOneWidget);
    expect(find.byKey(const Key('meal-steps-soon')), findsNothing);
  });

  testWidgets('details without steps warn about avoided allergens', (
    tester,
  ) async {
    catalog.detailMeal = _detail(
      steps: const <String>[],
      warnings: const <String>['MILK'],
    );
    await _pump(tester, catalog, const MealDetailScreen(mealId: 1));
    expect(
      find.byKey(const Key('meal-steps-soon'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('meal-allergen-warning'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.textContaining('الحليب', skipOffstage: false), findsWidgets);
  });

  testWidgets('favourites shows liked and disliked sections', (tester) async {
    await _pump(tester, catalog, const FavouritesScreen());
    expect(find.byKey(const Key('favourites-like-title')), findsOneWidget);
    expect(find.byKey(const Key('favourites-dislike-title')), findsOneWidget);
    expect(find.text('شاي'), findsOneWidget);
    expect(find.text('غداء'), findsOneWidget);
  });

  testWidgets('an empty local catalog shows the offline state', (tester) async {
    catalog.offline = true;
    await _pump(tester, catalog, const MealsScreen());
    expect(find.byKey(const Key('meals-offline-empty')), findsOneWidget);
    expect(find.byKey(const Key('meals-retry')), findsOneWidget);
  });

  testWidgets('English browse stays LTR at text scale 1.3', (tester) async {
    await _pump(
      tester,
      catalog,
      const MealsScreen(),
      locale: const Locale('en'),
      textScale: 1.3,
    );
    expect(find.text('Browse meals'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(MealsScreen))),
      TextDirection.ltr,
    );
  });
}

MealDetail _detail({
  required List<String> steps,
  List<String> warnings = const <String>[],
}) {
  return MealDetail(
    mealId: 1,
    name: 'شاي',
    cuisineName: 'مصري',
    servingGrams: 200,
    kcal: 10,
    proteinG: 1,
    carbG: 2,
    fatG: 0,
    sodiumPerServing: 12,
    saturatedFatPerServing: 1,
    nutrients: const <NutrientLine>[
      NutrientLine(code: 'protein', unit: 'g', perServing: 1, per100g: 1),
    ],
    ingredients: const <IngredientLine>[
      IngredientLine(name: 'شاي', gramsPerServing: 5, isOptional: false),
    ],
    steps: steps,
    iconName: 'sunrise',
    stance: null,
    warningAllergenCodes: warnings,
  );
}

Future<void> _pump(
  WidgetTester tester,
  _FakeCatalog catalog,
  Widget home, {
  Locale locale = const Locale('ar'),
  double textScale = 1,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(catalog),
        catalogSyncProvider.overrideWithValue(const NoopCatalogSync()),
      ],
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _FakeCatalog implements CatalogRepository {
  MealQuery? last;
  bool offline = false;
  MealDetail? detailMeal;

  static final _meals = <MealSummary>[
    const MealSummary(
      mealId: 1,
      name: 'شاي',
      kcal: 10,
      proteinG: 1,
      cuisineCode: 'eg',
      cuisineName: 'مصري',
      tags: <String>[breakfastTag],
      iconName: 'sunrise',
      liked: true,
      allergenWarning: false,
    ),
    const MealSummary(
      mealId: 2,
      name: 'غداء',
      kcal: 20,
      proteinG: 2,
      cuisineCode: 'sy',
      cuisineName: 'شامي',
      tags: <String>[lunchTag],
      iconName: 'sun',
      liked: false,
      allergenWarning: false,
    ),
    const MealSummary(
      mealId: 3,
      name: 'حليب',
      kcal: 30,
      proteinG: 3,
      cuisineCode: 'eg',
      cuisineName: 'مصري',
      tags: <String>[breakfastTag],
      iconName: 'sunrise',
      liked: false,
      allergenWarning: true,
    ),
  ];

  @override
  Future<MealBrowsePage> browse(MealQuery query) async {
    last = query;
    if (offline) {
      return const MealBrowsePage(meals: [], cuisines: [], status: null);
    }
    final meals = <MealSummary>[
      for (final meal in _meals)
        if (_matches(meal, query)) meal,
    ];
    return MealBrowsePage(
      meals: meals,
      cuisines: const <CuisineOption>[
        CuisineOption(code: 'eg', name: 'مصري'),
        CuisineOption(code: 'sy', name: 'شامي'),
      ],
      status: CatalogStatus(
        mealCount: 2,
        fetchedAt: DateTime.utc(2026, 1, 1, 8),
      ),
    );
  }

  @override
  Future<MealDetail?> detail(int mealId) async => detailMeal;

  @override
  Future<MealFavourites> favourites() async {
    return MealFavourites(
      liked: <MealSummary>[_meals[0]],
      disliked: <MealSummary>[_meals[1]],
    );
  }
}

bool _matches(MealSummary meal, MealQuery query) {
  if (query.text.isNotEmpty && !meal.name.contains(query.text)) {
    return false;
  }
  if (query.occasionTag != null && !meal.tags.contains(query.occasionTag)) {
    return false;
  }
  if (query.cuisineCode != null && meal.cuisineCode != query.cuisineCode) {
    return false;
  }
  if (query.hideAvoided && meal.allergenWarning) {
    return false;
  }
  return true;
}
