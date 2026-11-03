import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/l10n/app_localizations.dart';
import 'package:nutriguide/core/theme/app_theme.dart';
import 'package:nutriguide/features/plan/data/plan_providers.dart';
import 'package:nutriguide/features/plan/data/plan_sync.dart';
import 'package:nutriguide/features/plan/data/week_build_marker.dart';
import 'package:nutriguide/features/plan/domain/plan.dart';
import 'package:nutriguide/features/plan/domain/plan_dates.dart';
import 'package:nutriguide/features/plan/domain/week_generator.dart';
import 'package:nutriguide/features/plan/presentation/showcase_controller.dart';
import 'package:nutriguide/features/plan/presentation/week_build_pill.dart';

import '../../support/plan_samples.dart';

void main() {
  final today = DateTime(2026, 11, 3);
  final week = <String>[for (final date in weekDates(today)) isoDate(date)];

  late _MemoryMarker marker;
  late Set<String> stored;
  late Future<DayPlan> Function(DateTime date) createDay;
  late StreamController<List<DayPlan>> plans;

  DayPlan ok(DateTime date) {
    return sampleDay(planDate: isoDate(date), stats: sampleStats());
  }

  List<DayPlan> storedPlans() => <DayPlan>[
    for (final iso in week)
      if (stored.contains(iso)) sampleDay(planDate: iso, stats: sampleStats()),
  ];

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        planClockProvider.overrideWithValue(() => today),
        weekBuildMarkerProvider.overrideWithValue(marker),
        planSyncProvider.overrideWithValue(const NoopPlanSync()),
        // Like the database watch, a new listener gets the current rows.
        weekPlansProvider.overrideWith((ref) async* {
          yield storedPlans();
          yield* plans.stream;
        }),
        weekGeneratorProvider.overrideWithValue(
          WeekGenerator(
            createDay: (DateTime date) => createDay(date),
            isLogged: (DateTime date) async => false,
            storeDay: (DayPlan plan) async {
              stored.add(plan.planDate);
              plans.add(storedPlans());
            },
            hasPlan: (DateTime date) async => stored.contains(isoDate(date)),
            now: () => today,
            wait: (Duration duration) async {},
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    marker = _MemoryMarker();
    stored = <String>{};
    createDay = (DateTime date) async => ok(date);
    plans = StreamController<List<DayPlan>>.broadcast();
  });

  tearDown(() => plans.close());

  group('ShowcaseController', () {
    test('a full build marks the week pending, then clears it', () async {
      final c = container();
      final run = c.read(showcaseControllerProvider.notifier).start();
      expect(marker.marks.first, isTrue);
      await run;

      expect(stored, hasLength(7));
      expect(marker.value, isFalse);
    });

    test('a network stop keeps the week pending for the next open', () async {
      createDay = (DateTime date) async {
        if (isoDate(date) == week[3]) {
          throw const PlanRequestException(network: true);
        }
        return ok(date);
      };
      final c = container();
      await c.read(showcaseControllerProvider.notifier).start();

      expect(stored, hasLength(3));
      expect(marker.value, isTrue);
    });

    test('resume builds only the missing days', () async {
      marker.value = true;
      stored.addAll(week.take(3));
      final calls = <String>[];
      createDay = (DateTime date) async {
        calls.add(isoDate(date));
        return ok(date);
      };
      final c = container();
      await c.read(showcaseControllerProvider.notifier).resume();

      expect(calls, week.skip(3).toList());
      expect(marker.value, isFalse);
    });

    test('resume does nothing when no build was left unfinished', () async {
      var calls = 0;
      createDay = (DateTime date) async {
        calls += 1;
        return ok(date);
      };
      final c = container();
      await c.read(showcaseControllerProvider.notifier).resume();

      expect(calls, 0);
      expect(c.read(showcaseControllerProvider).running, isFalse);
    });

    test('a final stop such as NOT_ELIGIBLE clears the mark', () async {
      createDay = (DateTime date) async =>
          throw const PlanRequestException(code: 'NOT_ELIGIBLE');
      final c = container();
      await c.read(showcaseControllerProvider.notifier).start();

      expect(marker.value, isFalse);
    });
  });

  group('WeekBuildPill', () {
    Future<ProviderContainer> pumpPill(WidgetTester tester) async {
      final c = container();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: WeekBuildPill()),
          ),
        ),
      );
      return c;
    }

    testWidgets('hidden before any build', (tester) async {
      await pumpPill(tester);
      expect(find.byKey(const Key('week-build-pill')), findsNothing);
      expect(find.byKey(const Key('week-build-failed')), findsNothing);
    });

    testWidgets('counts the built days while the week builds', (tester) async {
      final gates = <String, Completer<DayPlan>>{
        for (final iso in week) iso: Completer<DayPlan>(),
      };
      createDay = (DateTime date) => gates[isoDate(date)]!.future;
      final c = await pumpPill(tester);
      unawaited(c.read(showcaseControllerProvider.notifier).start());
      await tester.pump();

      gates[week[0]]!.complete(ok(DateTime.parse(week[0])));
      await tester.pump();
      await tester.pump();
      expect(find.text('نبني باقي الأسبوع 1/7'), findsOneWidget);

      gates[week[1]]!.complete(ok(DateTime.parse(week[1])));
      await tester.pump();
      await tester.pump();
      expect(find.text('نبني باقي الأسبوع 2/7'), findsOneWidget);

      for (final iso in week.skip(2)) {
        gates[iso]!.complete(ok(DateTime.parse(iso)));
        await tester.pump();
        await tester.pump();
      }
      await tester.pump();
      expect(find.byKey(const Key('week-build-pill')), findsNothing);
      expect(find.byKey(const Key('week-build-failed')), findsNothing);
    });

    testWidgets('a stopped build offers a retry that builds the rest', (
      tester,
    ) async {
      var fail = true;
      createDay = (DateTime date) async {
        if (fail && isoDate(date) == week[5]) {
          throw const PlanRequestException(network: true);
        }
        return ok(date);
      };
      final c = await pumpPill(tester);
      unawaited(c.read(showcaseControllerProvider.notifier).start());
      for (var i = 0; i < 20; i += 1) {
        await tester.pump();
      }

      expect(find.text('لم نتمكن من بناء 2 من أيام الأسبوع'), findsOneWidget);

      fail = false;
      await tester.tap(find.byKey(const Key('week-build-retry')));
      for (var i = 0; i < 20; i += 1) {
        await tester.pump();
      }

      expect(stored, hasLength(7));
      expect(find.byKey(const Key('week-build-failed')), findsNothing);
    });
  });
}

class _MemoryMarker extends WeekBuildMarker {
  bool value = false;
  final List<bool> marks = <bool>[];

  @override
  Future<bool> pending() async => value;

  @override
  Future<void> mark(bool pending) async {
    marks.add(pending);
    value = pending;
  }
}
