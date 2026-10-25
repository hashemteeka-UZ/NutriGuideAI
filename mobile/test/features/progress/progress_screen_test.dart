import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/db/app_database.dart' hide PlanItem;
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/plan/data/plan_providers.dart';
import 'package:nutriguide/features/plan/data/user_context.dart';
import 'package:nutriguide/features/plan/domain/cached_user.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/pump_app.dart';

void main() {
  List<Override> at() {
    return <Override>[
      planClockProvider.overrideWithValue(() => DateTime(2026, 10, 25, 9)),
    ];
  }

  Future<AppDatabase> seeded({bool logs = true}) async {
    final database = AppDatabase(NativeDatabase.memory());
    final now = DateTime.utc(2026, 10, 25);
    const statuses = <String?>[
      'ACHIEVED',
      'PARTIAL',
      'ACHIEVED',
      'NOT_ACHIEVED',
      null,
      'ACHIEVED',
      'ACHIEVED',
    ];
    for (var index = 0; index < 7; index++) {
      final date = '2026-10-${19 + index}';
      final status = statuses[index];
      await database
          .into(database.adherenceDays)
          .insert(
            AdherenceDaysCompanion.insert(
              date: date,
              status: Value(status),
              targetKcal: const Value(1540),
              kcal: Value(status == null ? null : 1400.0 + index * 20),
              proteinG: const Value(100),
              carbG: const Value(150),
              fatG: const Value(50),
              unmetJson: index == 1
                  ? '[{"nutrient":"fiber","minimum":22,"total":15}]'
                  : '[]',
              exceededJson: index == 3
                  ? '[{"nutrient":"sodium","limit":2000,"total":2400}]'
                  : '[]',
              planItemsTotal: 4,
              planItemsConsumed: logs && status != null ? 3 : 0,
              logCount: logs && status != null ? 3 : 0,
              fetchedAt: now,
            ),
          );
    }
    await database
        .into(database.progressMeta)
        .insert(ProgressMetaCompanion.insert(key: 'streak', value: '2'));
    for (final (date, kg) in <(String, double)>[
      ('2026-10-01', 80.0),
      ('2026-10-12', 79.2),
      ('2026-10-25', 78.5),
    ]) {
      await database
          .into(database.weights)
          .insert(
            WeightsCompanion.insert(
              measuredOn: date,
              weightKg: kg,
              updatedAt: now,
              state: 'CONFIRMED',
            ),
          );
    }
    return database;
  }

  Future<void> openProgress(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tab-progress')));
    await tester.pumpAndSettle();
  }

  testNutriguide('arabic weekly report from the cache', (tester) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: at(),
    );
    await openProgress(tester);
    expect(find.text('19 أكتوبر – 25 أكتوبر'), findsOneWidget);
    expect(find.byKey(const Key('progress-ring')), findsOneWidget);
    // 4 ACHIEVED of 6 logged days with a status.
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('أسبوع جيد'), findsOneWidget);
    expect(find.text('حققت هدفك في 4 من 6 أيام'), findsOneWidget);
    expect(find.byKey(const Key('card-best-day')), findsOneWidget);
    expect(find.byKey(const Key('card-most-missed')), findsOneWidget);
    expect(find.byKey(const Key('card-water')), findsNothing);
    final chart = tester.getSemantics(
      find.byKey(const Key('progress-calories-chart')),
    );
    expect(chart.label, contains('لا تسجيل'));
    await tester.scrollUntilVisible(
      find.byKey(const Key('progress-calendar')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('progress-screen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.byKey(const Key('progress-exceeded')), findsOneWidget);
    expect(find.text('🔥 2 أيام متتالية'), findsOneWidget);
    // The offline fake failed the refresh: the cache shows with the bar.
    expect(find.text('دون اتصال · تعرض آخر نسخة محفوظة'), findsOneWidget);
  });

  testNutriguide('previous week is empty and next is disabled at the start', (
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
    await openProgress(tester);
    final next = tester.widget<IconButton>(find.byKey(const Key('week-next')));
    expect(next.onPressed, isNull);
    await tester.tap(find.byKey(const Key('week-prev')));
    await tester.pumpAndSettle();
    expect(find.text('12 أكتوبر – 18 أكتوبر'), findsOneWidget);
    expect(find.byKey(const Key('progress-empty-week')), findsOneWidget);
    expect(
      find.text('سجّل وجباتك هذا الأسبوع لترى تقريرك هنا'),
      findsOneWidget,
    );
  });

  testNutriguide('general mode hides the ring', (tester) async {
    final database = await seeded();
    addTearDown(database.close);
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: at(),
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
            conditions: <String>[],
            allergenCodes: <String>[],
            hasDislike: false,
          ),
        );
    await openProgress(tester);
    expect(find.byKey(const Key('progress-ring')), findsNothing);
    expect(find.byKey(const Key('progress-calories')), findsOneWidget);
  });

  testNutriguide('weight segment: tiles, change and a static chart', (
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
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('today-screen'))),
    );
    container
        .read(userContextProvider.notifier)
        .replace(
          const CachedUser(
            eligible: true,
            goalType: 'LOSE',
            conditions: <String>[],
            allergenCodes: <String>[],
            hasDislike: false,
            targetWeightKg: 75,
          ),
        );
    await openProgress(tester);
    await tester.tap(find.text('الوزن').last);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('weight-tile-now')),
        matching: find.text('78.5 كغ'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('weight-tile-goal')),
        matching: find.text('75.0 كغ'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('−1.5'), findsOneWidget);
    // Reduce motion is on in widget tests: the line is drawn at once.
    expect(find.byKey(const Key('weight-chart-static')), findsOneWidget);
    expect(find.byKey(const Key('weight-chart-animated')), findsNothing);
  });

  testNutriguide('one weight shows the tiles and the hint', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database
        .into(database.weights)
        .insert(
          WeightsCompanion.insert(
            measuredOn: '2026-10-25',
            weightKg: 78.5,
            updatedAt: DateTime.utc(2026, 10, 25),
            state: 'CONFIRMED',
          ),
        );
    await pumpNutriguide(
      tester,
      auth: _signedIn(),
      database: database,
      extra: at(),
    );
    await openProgress(tester);
    await tester.tap(find.text('الوزن').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weight-few-points')), findsOneWidget);
    expect(find.byKey(const Key('weight-change')), findsNothing);
  });

  testNutriguide('english at 1.3: both segments without overflow', (
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
      extra: at(),
    );
    await openProgress(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('19 October – 25 October'), findsOneWidget);
    expect(find.text('You hit your goal on 4 of 6 days'), findsOneWidget);
    expect(find.byKey(const Key('progress-ring')), findsOneWidget);
    await tester.tap(find.text('Weight').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('progress-weight')), findsOneWidget);
  });
}

FakeAuthRepository _signedIn() {
  return FakeAuthRepository(
    restored: const SignedIn(
      account: AccountInfo(hasProfile: true, email: 'a@b.co'),
    ),
  );
}
