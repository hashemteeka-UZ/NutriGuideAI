import 'dart:math' as math;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/db/app_database.dart' hide PlanItem;
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/reminders/domain/reminders.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_notifications.dart';
import '../../support/pump_app.dart';

void main() {
  group('plan (#313)', () {
    const starts = <String, int>{
      'BREAKFAST': 7 * 60 + 30,
      'LUNCH': 13 * 60,
      'DINNER': 19 * 60,
      'SNACK': 16 * 60 + 15,
    };

    test('all off schedules nothing', () {
      expect(
        planReminders(
          const ReminderSettings(),
          mealStarts: starts,
          hasWaterGoal: true,
        ),
        isEmpty,
      );
    });

    test('meals: one per window start, ids 100-103', () {
      final specs = planReminders(
        const ReminderSettings(meals: true),
        mealStarts: starts,
        hasWaterGoal: true,
      );
      expect(specs.map((s) => s.id), <int>[100, 101, 102, 103]);
      expect(specs.map((s) => '${s.hour}:${s.minute}'), <String>[
        '7:30',
        '13:0',
        '19:0',
        '16:15',
      ]);
      expect(specs.every((s) => s.route == '/today'), isTrue);
      final three = planReminders(
        const ReminderSettings(meals: true),
        mealStarts: <String, int>{...starts}..remove('SNACK'),
        hasWaterGoal: true,
      );
      expect(three, hasLength(3));
    });

    test('water: 7 a day from 09:00 to 21:00, only with a goal', () {
      final specs = planReminders(
        const ReminderSettings(water: true),
        mealStarts: starts,
        hasWaterGoal: true,
      );
      expect(specs.map((s) => s.hour), <int>[9, 11, 13, 15, 17, 19, 21]);
      expect(specs.map((s) => s.id).toSet(), hasLength(7));
      expect(specs.first.route, '/water');
      expect(
        planReminders(
          const ReminderSettings(water: true),
          mealStarts: starts,
          hasWaterGoal: false,
        ),
        isEmpty,
      );
    });

    test('weigh-in: Friday 09:00, one id', () {
      final specs = planReminders(
        const ReminderSettings(weighIn: true),
        mealStarts: starts,
        hasWaterGoal: false,
      );
      expect(specs.single.id, weighInId);
      expect(specs.single.weekday, DateTime.friday);
      expect(specs.single.hour, 9);
      expect(specs.single.route, '/progress');
    });

    test('clock text', () {
      expect(clockMinutes('08:05'), 485);
      expect(clockMinutes('x'), isNull);
    });
  });

  group('screen', () {
    Future<AppDatabase> seeded({bool waterGoal = true}) async {
      final database = AppDatabase(NativeDatabase.memory());
      for (final (slot, start) in <(String, String)>[
        ('BREAKFAST', '07:00'),
        ('LUNCH', '13:00'),
        ('DINNER', '19:00'),
      ]) {
        await database
            .into(database.mealWindows)
            .insert(
              MealWindowsCompanion.insert(
                windowDate: '2026-10-24',
                slot: slot,
                start: start,
                end: '23:00',
              ),
            );
      }
      await database
          .into(database.daySummaries)
          .insert(
            DaySummariesCompanion.insert(
              summaryDate: '2026-10-24',
              planItemsTotal: 0,
              planItemsConsumed: 0,
              totalMl: 0,
              goalMl: Value(waterGoal ? 2000 : null),
              requiresClinician: false,
              fetchedAt: DateTime.utc(2026, 10, 24),
            ),
          );
      return database;
    }

    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('tab-me')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-reminders')));
      await tester.pumpAndSettle();
    }

    testNutriguide('all off by default; meals on schedules the windows', (
      tester,
    ) async {
      final database = await seeded();
      addTearDown(database.close);
      final fake = FakeNotificationsGateway();
      await pumpNutriguide(
        tester,
        auth: _signedIn(),
        database: database,
        notifications: fake,
      );
      await open(tester);
      for (final kind in ReminderKind.values) {
        final tile = tester.widget<SwitchListTile>(
          find.byKey(Key('reminder-${kind.name}')),
        );
        expect(tile.value, isFalse);
      }
      await tester.tap(find.byKey(const Key('reminder-meals')));
      await tester.pumpAndSettle();
      expect(fake.permissionRequests, 1);
      expect(fake.scheduled.keys.toSet(), <int>{100, 101, 102});
      expect(fake.scheduled[100]!.hour, 7);
      expect(fake.scheduled[100]!.body, contains('فطور'));

      await tester.tap(find.byKey(const Key('reminder-water')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reminder-weighIn')));
      await tester.pumpAndSettle();
      expect(fake.scheduled, hasLength(3 + 7 + 1));
      expect(fake.scheduled[weighInId]!.weekday, DateTime.friday);

      await tester.tap(find.byKey(const Key('reminder-meals')));
      await tester.pumpAndSettle();
      expect(fake.scheduled, hasLength(7 + 1));
    });

    testNutriguide(
      'subtitles are not cut and off switches are visible (#319)',
      (tester) async {
        final database = await seeded();
        addTearDown(database.close);
        await pumpNutriguide(
          tester,
          auth: _signedIn(),
          database: database,
          notifications: FakeNotificationsGateway(),
        );
        await open(tester);
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byKey(const Key('reminders-screen'))),
          ).scale(10),
          10,
        );
        for (final kind in ReminderKind.values) {
          final tile = find.byKey(Key('reminder-${kind.name}'));
          final paragraphs = tester.renderObjectList<RenderParagraph>(
            find.descendant(of: tile, matching: find.byType(RichText)),
          );
          expect(paragraphs, isNotEmpty);
          for (final paragraph in paragraphs) {
            expect(paragraph.didExceedMaxLines, isFalse);
          }
        }
        final context = tester.element(
          find.byKey(const Key('reminders-screen')),
        );
        final theme = Theme.of(context);
        final off = theme.switchTheme.thumbColor!.resolve(<WidgetState>{})!;
        final ratio = _contrast(off, theme.scaffoldBackgroundColor);
        expect(ratio, greaterThanOrEqualTo(3));
      },
    );

    testNutriguide('denied permission keeps the switch off', (tester) async {
      final database = await seeded();
      addTearDown(database.close);
      final fake = FakeNotificationsGateway(granted: false);
      await pumpNutriguide(
        tester,
        auth: _signedIn(),
        database: database,
        notifications: fake,
      );
      await open(tester);
      await tester.tap(find.byKey(const Key('reminder-meals')));
      await tester.pumpAndSettle();
      final tile = tester.widget<SwitchListTile>(
        find.byKey(const Key('reminder-meals')),
      );
      expect(tile.value, isFalse);
      expect(find.byKey(const Key('reminders-denied')), findsOneWidget);
      expect(fake.scheduled, isEmpty);
      await tester.tap(find.byKey(const Key('reminders-open-settings')));
      await tester.pump();
      expect(fake.settingsOpened, 1);
    });

    testNutriguide('no water goal: a hint instead of the reminder', (
      tester,
    ) async {
      final database = await seeded(waterGoal: false);
      addTearDown(database.close);
      final fake = FakeNotificationsGateway();
      await pumpNutriguide(
        tester,
        auth: _signedIn(),
        database: database,
        notifications: fake,
      );
      await open(tester);
      await tester.tap(find.byKey(const Key('reminder-water')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reminders-need-goal')), findsOneWidget);
      expect(fake.scheduled, isEmpty);
    });

    testNutriguide('logout cancels every reminder', (tester) async {
      final database = await seeded();
      addTearDown(database.close);
      final fake = FakeNotificationsGateway();
      await pumpNutriguide(
        tester,
        auth: _signedIn(),
        database: database,
        notifications: fake,
      );
      await open(tester);
      await tester.tap(find.byKey(const Key('reminder-weighIn')));
      await tester.pumpAndSettle();
      expect(fake.scheduled, hasLength(1));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final logout = find.byKey(const Key('account-logout'));
      await tester.scrollUntilVisible(
        logout,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('account-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(logout);
      await tester.pumpAndSettle();
      expect(fake.scheduled, isEmpty);
      expect(fake.cancelAllCalls, greaterThanOrEqualTo(2));
    });
  });
}

FakeAuthRepository _signedIn() {
  return FakeAuthRepository(
    restored: const SignedIn(
      account: AccountInfo(hasProfile: true, email: 'a@b.co'),
    ),
  );
}

double _contrast(Color a, Color b) {
  final high = math.max(a.computeLuminance(), b.computeLuminance());
  final low = math.min(a.computeLuminance(), b.computeLuminance());
  return (high + 0.05) / (low + 0.05);
}
