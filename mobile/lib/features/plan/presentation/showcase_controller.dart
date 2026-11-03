import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plan_providers.dart';
import '../data/plan_sync.dart';
import '../data/user_context.dart';
import '../data/week_build_marker.dart';
import '../domain/plan.dart';
import '../domain/plan_dates.dart';
import '../domain/week_generator.dart';

class ShowcaseDay {
  const ShowcaseDay({
    required this.date,
    this.kcal,
    this.failed = false,
    this.done = false,
  });

  final DateTime date;
  final int? kcal;
  final bool failed;
  final bool done;
}

class ShowcaseState {
  const ShowcaseState({
    required this.days,
    this.step = 0,
    this.running = false,
    this.finished = false,
    this.built = 0,
    this.failed = 0,
    this.stopCode,
    this.retryAfterSeconds,
    this.dayOne,
    this.latest,
    this.currentDate,
    this.dayStartedAt,
    this.candidateMeals,
  });

  final int step;
  final bool running;
  final bool finished;
  final int built;
  final int failed;
  final String? stopCode;
  final int? retryAfterSeconds;
  final DayPlan? dayOne;

  /// The day built last; the optimizer view shows its meals.
  final DayPlan? latest;

  /// The day the server is building now, and when its request started.
  final DateTime? currentDate;
  final DateTime? dayStartedAt;
  final int? candidateMeals;
  final List<ShowcaseDay> days;

  ShowcaseState copyWith({
    int? step,
    bool? running,
    bool? finished,
    int? built,
    int? failed,
    Object? stopCode = _keep,
    int? retryAfterSeconds,
    DayPlan? dayOne,
    DayPlan? latest,
    DateTime? currentDate,
    DateTime? dayStartedAt,
    int? candidateMeals,
    List<ShowcaseDay>? days,
  }) {
    return ShowcaseState(
      step: step ?? this.step,
      running: running ?? this.running,
      finished: finished ?? this.finished,
      built: built ?? this.built,
      failed: failed ?? this.failed,
      stopCode: identical(stopCode, _keep)
          ? this.stopCode
          : stopCode as String?,
      retryAfterSeconds: retryAfterSeconds ?? this.retryAfterSeconds,
      dayOne: dayOne ?? this.dayOne,
      latest: latest ?? this.latest,
      currentDate: currentDate ?? this.currentDate,
      dayStartedAt: dayStartedAt ?? this.dayStartedAt,
      candidateMeals: candidateMeals ?? this.candidateMeals,
      days: days ?? this.days,
    );
  }
}

class ShowcaseController extends Notifier<ShowcaseState> {
  var _started = false;

  @override
  ShowcaseState build() {
    ref.keepAlive();
    final now = ref.read(planClockProvider)();
    return ShowcaseState(
      days: <ShowcaseDay>[
        for (final date in weekDates(now)) ShowcaseDay(date: date),
      ],
    );
  }

  /// Builds the days still missing from an interrupted week build. Does
  /// nothing while a build runs or when no build was left unfinished.
  Future<void> resume() async {
    if (state.running) {
      return;
    }
    if (!await ref.read(weekBuildMarkerProvider).pending()) {
      return;
    }
    if (!ref.mounted || state.running) {
      return;
    }
    await start(force: true, onlyMissing: true);
  }

  /// Builds the days of this week that have no plan yet, after a failure.
  Future<void> retryMissing() => start(force: true, onlyMissing: true);

  Future<void> start({
    bool force = false,
    bool fromTomorrow = false,
    bool onlyMissing = false,
    Duration hold = Duration.zero,
  }) async {
    if (_started && (state.running || !force)) {
      return;
    }
    _started = true;
    final marker = ref.read(weekBuildMarkerProvider);
    unawaited(marker.mark(true));
    final now = ref.read(planClockProvider)();
    state = ShowcaseState(
      running: true,
      days: <ShowcaseDay>[
        for (final date in weekDates(now)) ShowcaseDay(date: date),
      ],
    );
    try {
      if (hold > Duration.zero) {
        await Future<void>.delayed(hold);
        if (!ref.mounted) {
          return;
        }
      }
      final generator = ref.read(weekGeneratorProvider);
      var pausedForOptimizer = false;
      await for (final event in generator.run(
        fromTomorrow: fromTomorrow,
        onlyMissing: onlyMissing,
      )) {
        if (!ref.mounted) {
          return;
        }
        state = _reduce(state, event);
        if (event is WeekDateStarted) {
          state = state.copyWith(
            currentDate: event.date,
            dayStartedAt: DateTime.now(),
          );
        }
        if (event is WeekFinished && !_resumable(event)) {
          unawaited(marker.mark(false));
        }
        if (event is WeekFinished && event.stopCode == 'NOT_ELIGIBLE') {
          ref.read(userContextProvider.notifier).markIneligible();
        }
        if (!pausedForOptimizer &&
            event is WeekDateDone &&
            hold > Duration.zero) {
          pausedForOptimizer = true;
          await Future<void>.delayed(hold);
          if (!ref.mounted) {
            return;
          }
        }
      }
      if (!ref.mounted) {
        return;
      }
      if (!state.finished) {
        state = state.copyWith(step: 4, running: false, finished: true);
      }
    } on Object {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        step: 4,
        running: false,
        finished: true,
        stopCode: state.stopCode ?? 'NETWORK',
      );
    }
    if (!ref.mounted) {
      return;
    }
    try {
      await ref.read(planSyncProvider).refresh();
    } on Object {
      // Built days stay in the cache. The offline bar covers a failed refresh.
    }
  }
}

const _keep = Object();

/// A build stopped by the network or a busy or slow planner is picked up again
/// on the next app open; any other end is final.
bool _resumable(WeekFinished event) {
  if (!event.stopped) {
    return false;
  }
  return switch (event.stopCode) {
    'NETWORK' ||
    'PLANNER_TIMEOUT' ||
    'PLANNER_BUSY' ||
    'RATE_LIMITED' ||
    'UNEXPECTED' => true,
    _ => false,
  };
}

ShowcaseState _reduce(ShowcaseState state, WeekEvent event) {
  return switch (event) {
    WeekDateStarted() => state.copyWith(step: state.step >= 2 ? 3 : 1),
    WeekDateDone(:final plan) => state.copyWith(
      step: state.step >= 2 ? 3 : 2,
      dayOne: state.dayOne ?? plan,
      latest: plan,
      candidateMeals: state.candidateMeals ?? plan.stats?.candidateMeals,
      days: <ShowcaseDay>[
        for (final day in state.days)
          if (isoDate(day.date) == plan.planDate)
            ShowcaseDay(
              date: day.date,
              kcal: plan.totals.kcal?.round(),
              done: true,
            )
          else
            day,
      ],
    ),
    WeekDateFailed(:final date) => state.copyWith(
      step: state.step >= 2 ? 3 : 2,
      days: <ShowcaseDay>[
        for (final day in state.days)
          if (_sameDay(day.date, date))
            ShowcaseDay(date: day.date, failed: true)
          else
            day,
      ],
    ),
    WeekFinished(
      :final built,
      :final failedDates,
      :final stopCode,
      :final retryAfterSeconds,
    ) =>
      state.copyWith(
        step: 4,
        running: false,
        finished: true,
        built: built,
        failed: failedDates.length,
        stopCode: stopCode,
        retryAfterSeconds: retryAfterSeconds,
      ),
  };
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

final showcaseControllerProvider =
    NotifierProvider<ShowcaseController, ShowcaseState>(ShowcaseController.new);

/// How long each early showcase step stays up when motion is enabled.
const showcaseStepHold = Duration(milliseconds: 1600);

Duration showcaseHoldFor(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : showcaseStepHold;
}
