import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nutriguide/core/db/app_database.dart' hide PlanItem;
import 'package:nutriguide/core/sync/outbox_store.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/plan/data/plan_providers.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/pump_app.dart';

void main() {
  Future<AppDatabase> seeded() async {
    final database = AppDatabase(NativeDatabase.memory());
    final now = DateTime.utc(2026, 10, 24);
    await database
        .into(database.plans)
        .insert(
          PlansCompanion.insert(
            planDate: '2026-10-24',
            planId: 1,
            algorithmVersion: 'cpsat_v2_learned',
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
            reasonCodes: '["LEARNED_PREFERENCE","HIGH_PROTEIN"]',
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
    return database;
  }

  List<Override> at(DateTime clock) {
    return <Override>[planClockProvider.overrideWithValue(() => clock)];
  }

  Future<List<Map<String, Object?>>> events(
    AppDatabase database,
    String type,
  ) async {
    final ops = await OutboxStore(database).pending(100);
    return <Map<String, Object?>>[
      for (final op in ops)
        if (op.payload['event_type'] == type) op.payload,
    ];
  }

  Future<void> start(
    WidgetTester tester,
    AppDatabase database,
    DateTime clock,
  ) {
    return pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: at(clock),
    );
  }

  Future<void> logFromToday(WidgetTester tester) async {
    final eat = find.byKey(const Key('eat-1'));
    await tester.scrollUntilVisible(
      eat,
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('today-screen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(eat);
    await tester.pumpAndSettle();
  }

  Future<void> openItem(WidgetTester tester) async {
    unawaited(
      GoRouter.of(tester.element(find.byKey(const Key('today-screen'))))
          .push<void>('/plan/item/1'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plan-item-screen')), findsOneWidget);
  }

  testNutriguide(
    'logging a plan item asks for a rating; 4 stars queue RATE 4',
    (tester) async {
      final database = await seeded();
      addTearDown(database.close);
      await start(tester, database, DateTime(2026, 10, 24, 9));
      await logFromToday(tester);
      expect(find.byKey(const Key('rating-sheet')), findsOneWidget);
      expect(find.text('كيف كانت الوجبة؟'), findsOneWidget);
      expect(find.bySemanticsLabel('4 من 5'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sheet-star-4')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rating-sheet')), findsNothing);
      expect(find.text('شكرًا، سنقترح ما يناسب ذوقك أكثر'), findsOneWidget);
      final rates = await events(database, 'RATE');
      expect(rates, hasLength(1));
      expect(rates.single['value'], 4);
      expect(rates.single['meal_id'], 10);
      expect(rates.single['plan_item_id'], 1);
      expect(rates.single['screen'], 'today');
    },
  );

  testNutriguide('«لاحقًا» closes the sheet and queues nothing', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await start(tester, database, DateTime(2026, 10, 24, 9));
    await logFromToday(tester);
    await tester.tap(find.byKey(const Key('rating-later')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rating-sheet')), findsNothing);
    expect(await events(database, 'RATE'), isEmpty);
  });

  testNutriguide('a logged item shows «قيّم الوجبة» with the chosen stars', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await start(tester, database, DateTime(2026, 10, 24, 9));
    await logFromToday(tester);
    await tester.tap(find.byKey(const Key('rating-later')));
    await tester.pumpAndSettle();
    await openItem(tester);
    expect(find.byKey(const Key('rate-meal-row')), findsOneWidget);
    expect(find.byKey(const Key('did-not-eat')), findsNothing);
    await tester.tap(find.byKey(const Key('rate-star-3')));
    await tester.pumpAndSettle();
    final row = find.byKey(const Key('rate-meal-row'));
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.star_rounded)),
      findsNWidgets(3),
    );
    final rates = await events(database, 'RATE');
    expect(rates.single['value'], 3);
    expect(rates.single['screen'], 'plan_item');
  });

  testNutriguide('«لم آكلها» confirmed queues one SKIP and shows the chip', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await start(tester, database, DateTime(2026, 10, 24, 13));
    await openItem(tester);
    await tester.tap(find.byKey(const Key('did-not-eat')));
    await tester.pumpAndSettle();
    expect(
      find.text('سنقلل اقتراح هذه الوجبة قليلًا. متابعة؟'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('did-not-eat-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('did-not-eat-marked')), findsOneWidget);
    expect(find.text('سُجلت: لم تؤكل'), findsOneWidget);
    expect(find.byKey(const Key('did-not-eat')), findsNothing);
    final skips = await events(database, 'SKIP');
    expect(skips, hasLength(1));
    expect(skips.single['plan_item_id'], 1);
    expect(skips.single['meal_id'], 10);
  });

  testNutriguide('cancel queues nothing', (tester) async {
    final database = await seeded();
    addTearDown(database.close);
    await start(tester, database, DateTime(2026, 10, 24, 13));
    await openItem(tester);
    await tester.tap(find.byKey(const Key('did-not-eat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('did-not-eat-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('did-not-eat')), findsOneWidget);
    expect(await events(database, 'SKIP'), isEmpty);
  });

  testNutriguide('no «لم آكلها» for a future day', (tester) async {
    final database = await seeded();
    addTearDown(database.close);
    await start(tester, database, DateTime(2026, 10, 23, 9));
    unawaited(
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push<void>('/plan/item/1'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plan-item-screen')), findsOneWidget);
    expect(find.byKey(const Key('did-not-eat')), findsNothing);
  });

  testNutriguide('the LEARNED_PREFERENCE chip reads «يناسب ذوقك»', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await start(tester, database, DateTime(2026, 10, 24, 9));
    await openItem(tester);
    expect(find.byKey(const Key('reason-LEARNED_PREFERENCE')), findsOneWidget);
    expect(find.text('يناسب ذوقك'), findsOneWidget);
  });
}

FakeAuthRepository _signedIn() {
  return FakeAuthRepository(
    restored: const SignedIn(
      account: AccountInfo(hasProfile: true, email: 'a@b.co'),
    ),
  );
}
