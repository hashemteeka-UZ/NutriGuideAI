import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/sync_changes.dart';
import 'package:nutriguide/core/api/manual/sync_models.dart';
import 'package:nutriguide/core/db/app_database.dart' hide PlanItem;
import 'package:nutriguide/core/sync/sync_api.dart';
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
            reasonCodes: '["HIGH_PROTEIN"]',
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
    return database;
  }

  List<Override> at(DateTime clock) {
    return <Override>[planClockProvider.overrideWithValue(() => clock)];
  }

  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('today-screen')),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is Scrollable &&
              axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
        ),
      ),
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  String calories(WidgetTester tester) {
    return tester.widget<Text>(find.byKey(const Key('calorie-value'))).data!;
  }

  testNutriguide(
    'tap «أكلتها» offline shows the check and the pending status',
    (tester) async {
      final database = await seeded();
      addTearDown(database.close);
      await pumpNutriguide(
        tester,
        auth: _signedIn(),
        database: database,
        extra: at(DateTime(2026, 10, 24, 9)),
      );
      expect(calories(tester), '0');
      await reveal(tester, find.byKey(const Key('eat-1')));
      await tester.tap(find.byKey(const Key('eat-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eat-done-1')), findsOneWidget);
      expect(find.text('سجلتها'), findsNothing);

      // The debounced sync runs and finds no connection.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('today-greeting')),
        -200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('today-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('⇡ 1 بانتظار الاتصال'), findsOneWidget);
      expect(calories(tester), '400');
      expect(find.text('مؤقت حتى المزامنة'), findsOneWidget);

      await reveal(tester, find.byKey(const Key('eat-undo-1')));
      await tester.tap(find.byKey(const Key('eat-undo-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eat-1')), findsOneWidget);
      expect(find.textContaining('بانتظار الاتصال'), findsNothing);
      // Compaction: no create and no delete left, only learning events.
      expect(await logOps(database), isEmpty);
      expect(await database.select(database.consumptionLogs).get(), isEmpty);
    },
  );

  testNutriguide('a window that ended unlogged shows the missed card', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: at(DateTime(2026, 10, 24, 13)),
    );
    await reveal(tester, find.byKey(const Key('missed-1')));
    expect(find.text('فاتك موعد فطور'), findsOneWidget);
    expect(
      find.text('هل أكلتها؟ سجلها الآن حتى يبقى يومك دقيقًا'),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('missed-1')),
        matching: find.byKey(const Key('eat-1')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('missed-1')), findsNothing);
    final log = await database.select(database.consumptionLogs).getSingle();
    expect(log.consumedAt.isAtSameMomentAs(DateTime(2026, 10, 24, 12)), isTrue);
  });

  testNutriguide('long-press offers a different amount', (tester) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: at(DateTime(2026, 10, 24, 9)),
    );
    await reveal(tester, find.byKey(const Key('eat-1')));
    await tester.longPress(find.byKey(const Key('eat-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eat-amount-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('eat-amount-0.5')));
    await tester.pumpAndSettle();
    final log = await database.select(database.consumptionLogs).getSingle();
    expect(log.servingsConsumed, 0.5);
  });

  testNutriguide('english Today with a logged meal at 1.3 does not overflow', (
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
      extra: at(DateTime(2026, 10, 24, 9)),
    );
    await reveal(tester, find.byKey(const Key('eat-1')));
    await tester.tap(find.byKey(const Key('eat-1')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('eat-done-1')), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testNutriguide('logout with logs that cannot be sent asks first', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    final auth = _signedIn();
    await pumpNutriguide(
      tester,
      auth: auth,
      database: database,
      extra: at(DateTime(2026, 10, 24, 9)),
    );
    await reveal(tester, find.byKey(const Key('eat-1')));
    await tester.tap(find.byKey(const Key('eat-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tab-me')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-logout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('logout-pending-dialog')), findsOneWidget);
    expect(
      find.text('لديك تسجيلات لم تُرفع بعد. الخروج سيحذفها من الهاتف.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('logout-pending-cancel')));
    await tester.pumpAndSettle();
    expect(auth.logoutCalls, 0);
    expect(await logOps(database), hasLength(1));

    await tester.tap(find.byKey(const Key('account-logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logout-pending-confirm')));
    await tester.pumpAndSettle();
    expect(auth.logoutCalls, 1);
  });

  testNutriguide('logout sends the outbox and signs out without asking', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    final auth = _signedIn();
    final api = _AcceptingSyncApi();
    await pumpNutriguide(
      tester,
      auth: auth,
      database: database,
      syncApi: api,
      extra: at(DateTime(2026, 10, 24, 9)),
    );
    await reveal(tester, find.byKey(const Key('eat-1')));
    await tester.tap(find.byKey(const Key('eat-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-me')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-logout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('logout-pending-dialog')), findsNothing);
    expect(api.uploaded, greaterThanOrEqualTo(1));
    expect(auth.logoutCalls, 1);
  });
}

/// Queued operations that are the user's records, not learning events.
Future<List<OutboxData>> logOps(AppDatabase database) {
  return (database.select(
    database.outbox,
  )..where((t) => t.opType.equals('INTERACTION_CREATE').not())).get();
}

FakeAuthRepository _signedIn() {
  return FakeAuthRepository(
    restored: const SignedIn(
      account: AccountInfo(hasProfile: true, email: 'a@b.co'),
    ),
  );
}

class _AcceptingSyncApi implements SyncApi {
  int uploaded = 0;

  @override
  Future<SyncBatchResult> upload(List<Map<String, Object?>> operations) async {
    uploaded += operations.length;
    return SyncBatchResult(
      results: <SyncOpOutcome>[
        for (final op in operations)
          SyncOpOutcome(
            opId: '${op['op_id']}',
            status: SyncOpStatus.created,
            entityId: 70,
          ),
      ],
      serverTime: DateTime.utc(2026, 10, 24, 9),
    );
  }

  @override
  Future<SyncChanges> changes(DateTime since) async {
    return SyncChanges.fromJson(<String, Object?>{
      'server_time': '2026-10-24T09:00:00Z',
      'consumption_logs': const <Object?>[],
      'deleted_consumption_log_ids': const <Object?>[],
      'water_logs': const <Object?>[],
      'deleted_water_log_ids': const <Object?>[],
      'weights': const <Object?>[],
      'plans': const <Object?>[],
      'meal_prefs': const <Object?>[],
      'profile_changed': false,
    });
  }
}
