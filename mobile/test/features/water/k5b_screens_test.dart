import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/water_day.dart';
import 'package:nutriguide/core/api/generated/models/weight_out.dart';
import 'package:nutriguide/core/db/app_database.dart' hide PlanItem;
import 'package:nutriguide/core/theme/app_theme.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/plan/data/plan_providers.dart';
import 'package:nutriguide/features/water/data/water_api.dart';
import 'package:nutriguide/features/water/presentation/water_screen.dart';
import 'package:nutriguide/features/weight/data/weight_repository.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/pump_app.dart';

void main() {
  final clock = DateTime(2026, 10, 25, 9);

  List<Override> at() {
    return <Override>[planClockProvider.overrideWithValue(() => clock)];
  }

  Future<AppDatabase> seeded({
    int? goalMl = 2000,
    bool clinician = false,
    String source = 'USER',
    bool withPlan = true,
  }) async {
    final database = AppDatabase(NativeDatabase.memory());
    final now = DateTime.utc(2026, 10, 25);
    if (withPlan) {
      await database
          .into(database.plans)
          .insert(
            PlansCompanion.insert(
              planDate: '2026-10-25',
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
              planDate: '2026-10-25',
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
              reasonCodes: '[]',
              wasSwapped: false,
              logged: false,
            ),
          );
    }
    await database
        .into(database.daySummaries)
        .insert(
          DaySummariesCompanion.insert(
            summaryDate: '2026-10-25',
            planItemsTotal: 1,
            planItemsConsumed: 0,
            totalMl: 750,
            goalMl: Value(goalMl),
            requiresClinician: clinician,
            waterSource: Value(source),
            fetchedAt: now,
          ),
        );
    return database;
  }

  testNutriguide('water tab adds a glass and shows the provisional total', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: at(),
    );
    await tester.tap(find.byKey(const Key('tab-water')));
    await tester.pumpAndSettle();
    expect(find.text('750 / 2,000 مل'), findsOneWidget);
    expect(find.text('هدف اليوم'), findsOneWidget);
    await tester.tap(find.byKey(const Key('water-add-250')));
    await tester.pumpAndSettle();
    expect(find.text('1,000 / 2,000 مل'), findsOneWidget);
    expect(find.byKey(const Key('water-provisional')), findsOneWidget);
    // Reduce motion is on in widget tests: the bottle does not wave.
    expect(find.byKey(const Key('water-wave-off')), findsOneWidget);

    // The Today card reads the same total.
    await tester.tap(find.byKey(const Key('tab-today')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('water-card')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('today-screen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('water-card')),
        matching: find.textContaining('1,000'),
      ),
      findsOneWidget,
    );
  });

  testNutriguide('custom amount above 500 shows the neutral tip', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: at(),
    );
    await tester.tap(find.byKey(const Key('tab-water')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('water-custom')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('water-large-tip')), findsNothing);
    await tester.tap(find.byKey(const Key('water-chip-750')));
    await tester.pumpAndSettle();
    expect(
      find.text('كمية كبيرة لمرة واحدة، يمكنك تقسيمها على مرتين.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('water-custom-add')));
    await tester.pumpAndSettle();
    final glass = await database.select(database.waterLogs).getSingle();
    expect(glass.amountMl, 750);
  });

  testNutriguide('doctor-set amount: no number until the goal is entered', (
    tester,
  ) async {
    final database = await seeded(
      goalMl: null,
      clinician: true,
      source: 'NONE',
    );
    addTearDown(database.close);
    final api = _GoalApi();
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      waterApi: api,
      extra: at(),
    );
    await tester.tap(find.byKey(const Key('tab-water')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('water-clinician-card')), findsOneWidget);
    expect(find.text('كمية الماء يحددها طبيبك'), findsOneWidget);
    expect(find.textContaining('/'), findsNothing);
    expect(find.byKey(const Key('water-bottle-card')), findsNothing);

    await tester.tap(find.byKey(const Key('water-doctor-goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('water-goal-save')));
    await tester.pumpAndSettle();
    expect(api.goals, <int>[1500]);
    expect(find.text('750 / 1,500 مل'), findsOneWidget);
    expect(find.text('الهدف الذي حدده طبيبك'), findsOneWidget);
  });

  testNutriguide('english water tab at 1.3 does not overflow', (tester) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      storedLocale: 'en',
      textScale: 1.3,
      logicalSize: const Size(390, 844),
      extra: at(),
    );
    await tester.tap(find.byKey(const Key('tab-water')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('750 / 2,000 ml'), findsOneWidget);
    await tester.tap(find.byKey(const Key('water-custom')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testNutriguide('quick sheet: four tiles with a plan, three without', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: at(),
    );
    await tester.tap(find.byKey(const Key('today-fab')));
    await tester.pumpAndSettle();
    expect(find.text('ماذا تريد أن تضيف؟'), findsOneWidget);
    for (final key in <String>[
      'quick-water',
      'quick-meal',
      'quick-weight',
      'quick-shopping',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
  });

  testNutriguide('quick sheet hides the shopping list without a plan', (
    tester,
  ) async {
    final database = await seeded(withPlan: false);
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: at(),
    );
    await tester.tap(find.byKey(const Key('today-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quick-weight')), findsOneWidget);
    expect(find.byKey(const Key('quick-shopping')), findsNothing);
  });

  testNutriguide('weight online: goal reached, then the new-target notice', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      weightApi: _GoalWeightApi(),
      extra: at(),
    );
    await tester.tap(find.byKey(const Key('today-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick-weight')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weight-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('weight-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('goal-reached-sheet')), findsOneWidget);
    expect(find.text('وصلت إلى هدفك!'), findsOneWidget);
    // Reduce motion: no burst animation.
    expect(find.byKey(const Key('goal-burst')), findsNothing);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(
      find.text('تم تحديث هدفك اليومي بناءً على وزنك الجديد'),
      findsWidgets,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byKey(const Key('target-later')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('target-notice')), findsNothing);
  });

  testNutriguide('weight offline is queued with a message', (tester) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: at(),
    );
    await tester.tap(find.byKey(const Key('tab-me')));
    await tester.pumpAndSettle();
    expect(find.text('لم تسجل وزنًا بعد'), findsOneWidget);
    await tester.tap(find.byKey(const Key('account-weight')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('weight-save')));
    await tester.pumpAndSettle();
    expect(find.text('حُفظ وزنك وسيُرفع عند الاتصال'), findsOneWidget);
    final ops = await database.select(database.outbox).get();
    expect(ops.where((op) => op.opType == 'WEIGHT_PUT'), hasLength(1));
    expect(find.textContaining('آخر وزن'), findsOneWidget);
  });

  testNutriguide('a MEAL log appears under «إضافات اليوم» with undo', (
    tester,
  ) async {
    final database = await seeded();
    addTearDown(database.close);
    await database
        .into(database.consumptionLogs)
        .insert(
          ConsumptionLogsCompanion.insert(
            clientUuid: 'm-1',
            kind: 'MEAL',
            mealId: const Value(42),
            logDate: '2026-10-25',
            slot: const Value('LUNCH'),
            servingsConsumed: const Value(1.5),
            consumedAt: DateTime.utc(2026, 10, 25, 7),
            name: const Value('شكشوكة'),
            kcal: const Value(450),
            state: 'PENDING',
          ),
        );
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: at(),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('extra-m-1')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('today-screen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('إضافات اليوم'), findsOneWidget);
    expect(find.textContaining('1½ حصة'), findsOneWidget);
    expect(find.textContaining('450 سعرة'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('extra-undo-m-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('extra-undo-m-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('extra-m-1')), findsNothing);
  });

  testWidgets('the bottle waves only when motion is on', (tester) async {
    Future<void> pump({required bool disable}) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: disable),
                child: const Center(
                  child: SizedBox(
                    width: 120,
                    height: 180,
                    child: WaterBottle(progress: 0.5),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    await pump(disable: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('water-wave-on')), findsOneWidget);
    await pump(disable: true);
    await tester.pump();
    expect(find.byKey(const Key('water-wave-off')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

FakeAuthRepository _signedIn() {
  return FakeAuthRepository(
    restored: const SignedIn(
      account: AccountInfo(hasProfile: true, email: 'a@b.co'),
    ),
  );
}

class _GoalApi extends WaterApi {
  _GoalApi() : super(Dio());

  final List<int> goals = <int>[];

  @override
  Future<WaterDay> day(DateTime date) async {
    final goal = goals.isEmpty ? null : goals.last;
    return WaterDay.fromJson(<String, Object?>{
      'date': '2026-10-25',
      'total_ml': 750,
      'goal': <String, Object?>{
        'goal_ml': goal,
        'reminders_default_off': true,
        'requires_clinician': true,
        'source': goal == null ? 'NONE' : 'USER',
      },
      'logs': const <Object?>[],
    });
  }

  @override
  Future<void> setGoal(int goalMl) async {
    goals.add(goalMl);
  }
}

class _GoalWeightApi extends WeightApi {
  _GoalWeightApi() : super(Dio());

  @override
  Future<WeightOut> put({
    required String measuredOn,
    required double weightKg,
    required DateTime updatedAt,
  }) async {
    return WeightOut.fromJson(<String, Object?>{
      'measured_on': measuredOn,
      'weight_kg': weightKg,
      'status': 'CREATED',
      'target_status': 'CREATED',
      'goal_reached': true,
      'new_target_id': 31,
    });
  }
}
