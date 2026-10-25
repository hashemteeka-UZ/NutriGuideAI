import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/db/app_database.dart' hide PlanItem;
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/plan/data/plan_providers.dart';
import 'package:nutriguide/features/progress/data/badge_service.dart';
import 'package:nutriguide/features/progress/domain/badges.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/pump_app.dart';

BadgeProgress _of(List<BadgeProgress> all, BadgeCode code) {
  return all.firstWhere((BadgeProgress b) => b.code == code);
}

Map<String, String?> _days(Map<int, String?> byDay) {
  return <String, String?>{
    for (final entry in byDay.entries)
      '2026-10-${entry.key.toString().padLeft(2, '0')}': entry.value,
  };
}

void main() {
  group('rules (#307)', () {
    test('nothing yet: every badge locked, water needs a goal', () {
      final all = evaluateBadges(const BadgeInputs());
      expect(all, hasLength(10));
      expect(all.where((b) => b.earned), isEmpty);
      expect(_of(all, BadgeCode.waterGoal3).needsWaterGoal, isTrue);
    });

    test('FIRST_LOG and EXPLORER_10 count non-deleted logs given', () {
      final all = evaluateBadges(
        const BadgeInputs(
          loggedMealIds: <int?>[1, 1, 2, null, 3, 4, 5, 6, 7, 8, 9],
        ),
      );
      expect(_of(all, BadgeCode.firstLog).earned, isTrue);
      final explorer = _of(all, BadgeCode.explorer10);
      expect(explorer.current, 9);
      expect(explorer.earned, isFalse);
      final ten = evaluateBadges(
        BadgeInputs(loggedMealIds: <int?>[for (var i = 1; i <= 10; i++) i]),
      );
      expect(_of(ten, BadgeCode.explorer10).earned, isTrue);
    });

    test('streaks: a gap breaks the run and PARTIAL does not count', () {
      final all = evaluateBadges(
        BadgeInputs(
          dayStatuses: _days(<int, String?>{
            1: 'ACHIEVED',
            2: 'ACHIEVED',
            3: 'PARTIAL',
            4: 'ACHIEVED',
            5: 'ACHIEVED',
            7: 'ACHIEVED', // day 6 missing: a gap
          }),
        ),
      );
      expect(longestAchievedRun(_days(<int, String?>{1: 'ACHIEVED'})), 1);
      expect(_of(all, BadgeCode.firstAchievedDay).earned, isTrue);
      final three = _of(all, BadgeCode.streak3);
      expect(three.current, 2);
      expect(three.earned, isFalse);
    });

    test('exactly 3 and 7 consecutive days earn STREAK_3 and STREAK_7', () {
      final all = evaluateBadges(
        BadgeInputs(
          dayStatuses: _days(<int, String?>{
            for (var day = 10; day <= 16; day++) day: 'ACHIEVED',
          }),
        ),
      );
      expect(_of(all, BadgeCode.streak3).earned, isTrue);
      expect(_of(all, BadgeCode.streak7).earned, isTrue);
      expect(_of(all, BadgeCode.streak14).current, 7);
      expect(_of(all, BadgeCode.streak30).earned, isFalse);
    });

    test('a streak crosses a month end', () {
      final statuses = <String, String?>{
        '2026-09-29': 'ACHIEVED',
        '2026-09-30': 'ACHIEVED',
        '2026-10-01': 'ACHIEVED',
      };
      expect(longestAchievedRun(statuses), 3);
    });

    test('BALANCED_WEEK: 5 achieved within any 7 consecutive dates', () {
      final four = _days(<int, String?>{
        1: 'ACHIEVED',
        2: 'ACHIEVED',
        4: 'ACHIEVED',
        7: 'ACHIEVED',
        8: 'ACHIEVED', // outside the 1-7 window
      });
      expect(bestSevenDayWindow(four), 4);
      expect(
        _of(
          evaluateBadges(BadgeInputs(dayStatuses: four)),
          BadgeCode.balancedWeek,
        ).earned,
        isFalse,
      );
      final five = <String, String?>{...four, '2026-10-05': 'ACHIEVED'};
      expect(bestSevenDayWindow(five), 5);
      expect(
        _of(
          evaluateBadges(BadgeInputs(dayStatuses: five)),
          BadgeCode.balancedWeek,
        ).earned,
        isTrue,
      );
    });

    test('WATER_GOAL_3 needs a goal and counts days at or above it', () {
      final noGoal = evaluateBadges(
        const BadgeInputs(waterByDate: <String, int>{'2026-10-01': 3000}),
      );
      expect(_of(noGoal, BadgeCode.waterGoal3).needsWaterGoal, isTrue);
      expect(_of(noGoal, BadgeCode.waterGoal3).current, 0);

      final withGoal = evaluateBadges(
        const BadgeInputs(
          waterByDate: <String, int>{
            '2026-10-01': 2000, // exactly the goal
            '2026-10-02': 1999,
            '2026-10-03': 2500,
            '2026-10-04': 1500, // its own lower goal
          },
          waterGoalByDate: <String, int?>{'2026-10-04': 1500},
          latestWaterGoal: 2000,
        ),
      );
      final water = _of(withGoal, BadgeCode.waterGoal3);
      expect(water.needsWaterGoal, isFalse);
      expect(water.current, 3);
      expect(water.earned, isTrue);
    });

    test('WEIGHT_TRACKER: 4 entries spanning at least 21 days', () {
      BadgeProgress tracker(List<String> dates) => _of(
        evaluateBadges(BadgeInputs(weightDates: dates)),
        BadgeCode.weightTracker,
      );
      expect(
        tracker(<String>['2026-10-01', '2026-10-05', '2026-10-10']).current,
        3,
      );
      // Four entries, but only 20 days apart: not yet.
      final close = tracker(<String>[
        '2026-10-01',
        '2026-10-05',
        '2026-10-10',
        '2026-10-21',
      ]);
      expect(close.earned, isFalse);
      expect(close.current, 3);
      final enough = tracker(<String>[
        '2026-10-01',
        '2026-10-05',
        '2026-10-10',
        '2026-10-22',
      ]);
      expect(enough.earned, isTrue);
    });
  });

  group('BadgeService (#306, #308)', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() => database.close());

    Future<void> log(String uuid, int mealId, String state) {
      return database
          .into(database.consumptionLogs)
          .insert(
            ConsumptionLogsCompanion.insert(
              clientUuid: uuid,
              kind: 'MEAL',
              mealId: Value(mealId),
              logDate: '2026-10-24',
              consumedAt: DateTime.utc(2026, 10, 24, 8),
              state: state,
            ),
          );
    }

    test('deleted logs are ignored; two runs give the same rows', () async {
      final service = BadgeService(
        database,
        now: () => DateTime(2026, 10, 25, 9),
      );
      await log('a', 1, 'DELETING');
      await log('b', 2, 'REJECTED');
      var items = await service.evaluate();
      expect(items.where((i) => i.earned), isEmpty);

      await log('c', 3, 'PENDING');
      items = await service.evaluate();
      final first = items.firstWhere((i) => i.code == BadgeCode.firstLog);
      expect(first.earned, isTrue);
      expect(first.earnedOn, '2026-10-25');
      expect(first.seen, isFalse);

      final later = BadgeService(database, now: () => DateTime(2026, 11, 2, 9));
      await later.evaluate();
      final rows = await database.select(database.earnedBadges).get();
      expect(rows, hasLength(1));
      expect(rows.single.earnedOn, '2026-10-25'); // the first date stays
    });

    test('an earned badge stays when its rows leave the cache', () async {
      final service = BadgeService(
        database,
        now: () => DateTime(2026, 10, 25, 9),
      );
      await log('c', 3, 'CONFIRMED');
      await service.evaluate();
      await database.delete(database.consumptionLogs).go();
      final items = await service.evaluate();
      final first = items.firstWhere((i) => i.code == BadgeCode.firstLog);
      expect(first.earned, isTrue);
      expect(first.progress.current, first.progress.target);
    });

    test('markSeen clears the new flag', () async {
      final service = BadgeService(
        database,
        now: () => DateTime(2026, 10, 25, 9),
      );
      await log('c', 3, 'CONFIRMED');
      await service.evaluate();
      await service.markSeen(<BadgeCode>[BadgeCode.firstLog]);
      final items = await service.evaluate();
      expect(
        items.firstWhere((i) => i.code == BadgeCode.firstLog).seen,
        isTrue,
      );
    });
  });

  group('grid', () {
    Future<AppDatabase> seeded() async {
      final database = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 10, 25);
      for (var day = 21; day <= 25; day++) {
        await database
            .into(database.adherenceDays)
            .insert(
              AdherenceDaysCompanion.insert(
                date: '2026-10-$day',
                status: Value(day == 22 ? 'PARTIAL' : 'ACHIEVED'),
                unmetJson: '[]',
                exceededJson: '[]',
                planItemsTotal: 4,
                planItemsConsumed: 3,
                logCount: 3,
                fetchedAt: now,
              ),
            );
      }
      return database;
    }

    List<Override> at() => <Override>[
      planClockProvider.overrideWithValue(() => DateTime(2026, 10, 25, 9)),
    ];

    Future<void> openBadges(WidgetTester tester, String label) async {
      await tester.tap(find.byKey(const Key('tab-progress')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    testNutriguide('10 badges, earned and locked, new ones shown once', (
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
      await openBadges(tester, 'الإنجازات');
      expect(find.byKey(const Key('badges-section')), findsOneWidget);
      final section = tester.element(find.byKey(const Key('badges-section')));
      expect(Directionality.of(section), TextDirection.rtl);
      for (final code in BadgeCode.values) {
        await tester.scrollUntilVisible(
          find.byKey(Key('badge-${code.code}')),
          200,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('progress-screen')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.byKey(Key('badge-${code.code}')), findsOneWidget);
      }
      // 23, 24, 25 in a row: STREAK_3 earned; STREAK_7 at 3 of 7.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('badge-status-STREAK_3')))
            .data,
        'حصلت عليها في 25 أكتوبر 2026',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('badge-status-STREAK_7')))
            .data,
        '3 من 7',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('badge-status-WATER_GOAL_3')))
            .data,
        'حدّد هدف الماء لتبدأ',
      );
      expect(find.byKey(const Key('badge-progress-STREAK_7')), findsOneWidget);
      expect(find.byKey(const Key('badge-progress-STREAK_3')), findsNothing);

      // New badges were celebrated once and are now marked seen.
      final rows = await database.select(database.earnedBadges).get();
      expect(rows.map((r) => r.code).toSet(), <String>{
        'FIRST_ACHIEVED_DAY',
        'STREAK_3',
      });
      expect(rows.every((r) => r.seen), isTrue);
    });

    testNutriguide('english labels', (tester) async {
      final database = await seeded();
      addTearDown(database.close);
      await pumpNutriguide(
        tester,
        auth: _signedIn(),
        database: database,
        storedLocale: 'en',
        extra: at(),
      );
      await openBadges(tester, 'Achievements');
      expect(find.text('3-day streak'), findsOneWidget);
      expect(find.textContaining('Well done! You earned'), findsWidgets);
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
