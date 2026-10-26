import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:nutriguide/core/db/app_database.dart' hide PlanItem;
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/plan/data/plan_providers.dart';
import 'package:nutriguide/features/plan/data/user_context.dart';
import 'package:nutriguide/features/plan/domain/cached_user.dart';
import 'package:nutriguide/features/plan/domain/plan.dart';
import 'package:nutriguide/features/plan/domain/week_generator.dart';
import 'package:nutriguide/features/shopping/data/shopping_providers.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/plan_samples.dart';
import '../../support/pump_app.dart';

void main() {
  final clock = DateTime(2026, 10, 24, 10, 30);

  Future<AppDatabase> seeded() async {
    final database = AppDatabase(NativeDatabase.memory());
    final now = DateTime.utc(2026, 10, 24);
    await database
        .into(database.plans)
        .insert(
          PlansCompanion.insert(
            planDate: '2026-10-24',
            planId: 1,
            algorithmVersion: 'cp-sat',
            createdAt: now,
            kcal: 1800,
            proteinG: 90,
            carbG: 180,
            fatG: 60,
            fiberG: 30,
            totalsKcal: const Value(1750),
            kcalWithin10pct: true,
            fetchedAt: now,
          ),
        );
    await database
        .into(database.plans)
        .insert(
          PlansCompanion.insert(
            planDate: '2026-10-25',
            planId: 2,
            algorithmVersion: 'cp-sat',
            createdAt: now,
            kcal: 1800,
            proteinG: 90,
            carbG: 180,
            fatG: 60,
            fiberG: 30,
            totalsKcal: const Value(1600),
            kcalWithin10pct: false,
            fetchedAt: now,
          ),
        );
    await database
        .into(database.planItems)
        .insert(
          PlanItemsCompanion.insert(
            planItemId: const Value(1),
            planDate: '2026-10-24',
            position: 0,
            slot: 'BREAKFAST',
            mealId: 10,
            mealName: 'فول',
            servingsMultiplier: 1,
            grams: 250,
            kcal: 400,
            proteinG: 20,
            carbG: 30,
            fatG: 10,
            reasonCodes: '["HIGH_PROTEIN","FITS_KCAL_TARGET"]',
            wasSwapped: false,
            logged: false,
          ),
        );
    await database
        .into(database.planItems)
        .insert(
          PlanItemsCompanion.insert(
            planItemId: const Value(2),
            planDate: '2026-10-25',
            position: 0,
            slot: 'LUNCH',
            mealId: 11,
            mealName: 'عدس',
            servingsMultiplier: 1,
            grams: 300,
            kcal: 500,
            proteinG: 25,
            carbG: 40,
            fatG: 12,
            reasonCodes: '[]',
            wasSwapped: false,
            logged: false,
          ),
        );
    await database
        .into(database.mealWindows)
        .insert(
          MealWindowsCompanion.insert(
            windowDate: '2026-10-24',
            slot: 'BREAKFAST',
            start: '08:00',
            end: '12:00',
          ),
        );
    await database
        .into(database.daySummaries)
        .insert(
          DaySummariesCompanion.insert(
            summaryDate: '2026-10-24',
            planItemsTotal: 1,
            planItemsConsumed: 0,
            totalMl: 0,
            goalMl: const Value(2000),
            requiresClinician: false,
            fetchedAt: now,
          ),
        );
    await database
        .into(database.meals)
        .insert(
          MealsCompanion.insert(
            lang: 'ar',
            mealId: 10,
            name: 'فول',
            searchKey: 'فول',
            servingGrams: 250,
            servings: 1,
            totalGrams: 250,
            kcal: 400,
            proteinG: 20,
            carbG: 30,
            fatG: 10,
            source: 'test',
            datasetVersion: 'v',
          ),
        );
    return database;
  }

  List<Override> clockOverride() {
    return <Override>[planClockProvider.overrideWithValue(() => clock)];
  }

  Finder verticalScroll(String screenKey) {
    return find.descendant(
      of: find.byKey(Key(screenKey)),
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is Scrollable &&
            axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
      ),
    );
  }

  Future<void> reveal(WidgetTester tester, String screenKey, Finder target) {
    return tester.scrollUntilVisible(
      target,
      240,
      scrollable: verticalScroll(screenKey),
    );
  }

  Future<void> lift(WidgetTester tester, String screenKey) async {
    await tester.drag(verticalScroll(screenKey), const Offset(0, -220));
    await tester.pumpAndSettle();
  }

  testNutriguide('shell tabs and back from another tab return to today', (
    tester,
  ) async {
    await pumpNutriguide(tester, auth: _signedIn(), extra: clockOverride());
    expect(find.byKey(const Key('today-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab-plan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plan-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab-water')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('water-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab-me')));
    await tester.pumpAndSettle();
    expect(find.text('وجباتي المفضلة'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('today-screen')), findsOneWidget);
  });

  testNutriguide(
    'today with a plan shows the calorie card, now card and chips',
    (tester) async {
      final database = await seeded();
      addTearDown(database.close);
      await pumpNutriguide(
        tester,
        auth: _signedIn(),
        database: database,
        extra: clockOverride(),
      );
      expect(find.byKey(const Key('calorie-card')), findsOneWidget);
      await reveal(tester, 'today-screen', find.byKey(const Key('now-card')));
      expect(find.byKey(const Key('now-card')), findsOneWidget);
      await reveal(
        tester,
        'today-screen',
        find.byKey(const Key('today-timeline')),
      );
      expect(find.byKey(const Key('today-timeline')), findsOneWidget);
      expect(find.text('غنية بالبروتين'), findsWidgets);
      expect(find.text('فول'), findsWidgets);
    },
  );

  testNutriguide('today without a plan shows the build card', (tester) async {
    await pumpNutriguide(tester, auth: _signedIn(), extra: clockOverride());
    expect(find.text('لم تُبنَ خطة اليوم بعد'), findsOneWidget);
    expect(find.byKey(const Key('build-week')), findsOneWidget);
  });

  testNutriguide('general mode today hides the plan and shows healthy meals', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: clockOverride(),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('today-screen'))),
    );
    container
        .read(userContextProvider.notifier)
        .replace(
          const CachedUser(
            eligible: false,
            goalType: 'MAINTAIN',
            conditions: <String>['DIABETES_T2'],
            allergenCodes: <String>[],
            hasDislike: false,
          ),
        );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('general-card')), findsOneWidget);
    expect(find.text('وجبات صحية لتجربتها'), findsOneWidget);
    expect(find.byKey(const Key('build-week')), findsNothing);
    await tester.tap(find.byKey(const Key('tab-plan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('general-plan-tip')), findsOneWidget);
  });

  testNutriguide('showcase steps and a partial week', (tester) async {
    final events = StreamController<WeekEvent>();
    addTearDown(events.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      extra: <Override>[
        ...clockOverride(),
        weekGeneratorProvider.overrideWith((ref) => _Scripted(events.stream)),
      ],
    );
    await tester.tap(find.byKey(const Key('build-week')));
    await tester.pump();
    expect(find.text('نبني خطتك الآن'), findsOneWidget);
    expect(find.text('سعرة يوميًا'), findsOneWidget);

    events.add(WeekDateStarted(clock));
    await tester.pump();
    expect(find.text('وجبة في المطبخ'), findsOneWidget);

    events.add(
      WeekDateDone(sampleDay(planDate: '2026-10-24', stats: sampleStats())),
    );
    await tester.pump();
    final lrm = String.fromCharCode(0x200E);
    expect(find.text('السعرات ضمن $lrm±10%$lrm'), findsOneWidget);

    events.add(WeekDateStarted(clock.add(const Duration(days: 1))));
    await tester.pump();
    expect(find.byKey(const Key('gen-day-24')), findsOneWidget);

    events.add(
      WeekFinished(
        built: 6,
        failedDates: <DateTime>[clock.add(const Duration(days: 2))],
        stopped: false,
      ),
    );
    await tester.pump();
    expect(find.text('بنينا 6 من 7 أيام'), findsOneWidget);
  });

  testNutriguide('plan tab switches days and describes the chart', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: clockOverride(),
    );
    await tester.tap(find.byKey(const Key('tab-plan')));
    await tester.pumpAndSettle();
    await reveal(tester, 'plan-screen', find.text('فول'));
    expect(find.text('فول'), findsWidgets);
    final kcal = NumberFormat.decimalPatternDigits(
      locale: 'ar',
      decimalDigits: 0,
    ).format(1750);
    expect(
      tester.getSemantics(find.byKey(const Key('plan-chart'))).label,
      contains(kcal),
    );
    await tester.tap(find.byKey(const Key('plan-day-2026-10-25')));
    await tester.pumpAndSettle();
    expect(find.text('عدس'), findsOneWidget);
  });

  testNutriguide('plan item details show the plan header and the swap sheet', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      planApi: _SwapApi(),
      extra: clockOverride(),
    );
    await tester.tap(find.byKey(const Key('tab-plan')));
    await tester.pumpAndSettle();
    await reveal(tester, 'plan-screen', find.byKey(const Key('plan-row-1')));
    await lift(tester, 'plan-screen');
    await tester.tap(find.byKey(const Key('plan-row-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plan-item-header')), findsOneWidget);
    expect(find.textContaining('كميتك'), findsOneWidget);
    expect(find.text('لماذا اخترناها لك؟'), findsOneWidget);
    // One serving: one donut, no repeated per-serving block (#315).
    expect(find.byKey(const Key('per-serving-facts')), findsNothing);
    await tester.tap(find.byKey(const Key('swap-button')));
    await tester.pumpAndSettle();
    expect(find.text('بدائل تناسب خطتك'), findsOneWidget);
    expect(find.text('شوربة'), findsOneWidget);
    expect(find.textContaining('+'), findsWidgets);
  });

  testNutriguide('shopping check survives leaving and share skips it', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.utc(2026, 10, 24);
    await database
        .into(database.shoppingLists)
        .insert(
          ShoppingListsCompanion.insert(
            rangeKey: '2026-10-24_2026-10-30',
            fetchedAt: now,
          ),
        );
    await database
        .into(database.shoppingItems)
        .insert(
          ShoppingItemsCompanion.insert(
            rangeKey: '2026-10-24_2026-10-30',
            ingredientId: 1,
            name: 'طماطم',
            grams: 346,
            meals: 2,
            checked: false,
          ),
        );
    await database
        .into(database.shoppingItems)
        .insert(
          ShoppingItemsCompanion.insert(
            rangeKey: '2026-10-24_2026-10-30',
            ingredientId: 2,
            name: 'بصل',
            grams: 1200,
            meals: 1,
            checked: false,
          ),
        );
    // Tap water is cooking water, not something to buy (#315).
    await database
        .into(database.shoppingItems)
        .insert(
          ShoppingItemsCompanion.insert(
            rangeKey: '2026-10-24_2026-10-30',
            ingredientId: 3,
            name: 'ماء',
            grams: 900,
            meals: 3,
            checked: false,
          ),
        );
    final share = _RecordShare();
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: <Override>[
        ...clockOverride(),
        textShareProvider.overrideWithValue(share),
      ],
    );
    await tester.tap(find.byKey(const Key('tab-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plan-shopping')));
    await tester.pumpAndSettle();
    final grams = NumberFormat.decimalPatternDigits(
      locale: 'ar',
      decimalDigits: 0,
    ).format(350);
    final kilos = NumberFormat.decimalPatternDigits(
      locale: 'ar',
      decimalDigits: 1,
    ).format(1.2);
    expect(find.textContaining(grams), findsWidgets);
    expect(find.textContaining(kilos), findsWidgets);
    await tester.tap(find.byKey(const Key('shop-item-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plan-shopping')));
    await tester.pumpAndSettle();
    final tile = tester.widget<CheckboxListTile>(
      find.byKey(const Key('shop-item-1')),
    );
    expect(tile.value, isTrue);
    await tester.tap(find.byKey(const Key('shop-share')));
    await tester.pump();
    expect(share.last, isNotNull);
    expect(share.last!, contains('بصل'));
    expect(share.last!, isNot(contains('طماطم')));
    expect(share.last!, isNot(contains('ماء')));
    expect(find.byKey(const Key('shop-item-3')), findsNothing);
  });

  testNutriguide('english today and plan at text scale 1.3 do not overflow', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      storedLocale: 'en',
      textScale: 1.3,
      logicalSize: const Size(390, 844),
      extra: clockOverride(),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('today-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab-plan')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('plan-screen')), findsOneWidget);
  });
}

FakeAuthRepository _signedIn() {
  return FakeAuthRepository(
    restored: const SignedIn(
      account: AccountInfo(hasProfile: true, email: 'a@b.co'),
    ),
  );
}

class _Scripted extends WeekGenerator {
  _Scripted(this.events)
    : super(
        createDay: (DateTime date) async => throw StateError('unused'),
        isLogged: (DateTime date) async => false,
        storeDay: (DayPlan plan) async {},
      );

  final Stream<WeekEvent> events;

  @override
  Stream<WeekEvent> run({bool fromTomorrow = false}) => events;
}

class _SwapApi extends SilentPlanApi {
  @override
  Future<List<PlanAlternative>> alternatives(int planItemId) async {
    return const <PlanAlternative>[
      PlanAlternative(
        mealId: 20,
        name: 'شوربة',
        kcal: 445,
        kcalDelta: 45,
        servingsMultiplier: 1,
      ),
    ];
  }
}

class _RecordShare implements TextShare {
  String? last;

  @override
  Future<void> share(String text) async {
    last = text;
  }
}
