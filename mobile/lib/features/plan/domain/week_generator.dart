import 'plan.dart';
import 'plan_dates.dart';

sealed class WeekEvent {
  const WeekEvent();
}

class WeekDateStarted extends WeekEvent {
  const WeekDateStarted(this.date);

  final DateTime date;
}

class WeekDateDone extends WeekEvent {
  const WeekDateDone(this.plan);

  final DayPlan plan;
}

class WeekDateFailed extends WeekEvent {
  const WeekDateFailed(this.date, this.code);

  final DateTime date;
  final String code;
}

class WeekFinished extends WeekEvent {
  const WeekFinished({
    required this.built,
    required this.failedDates,
    required this.stopped,
    this.stopCode,
    this.retryAfterSeconds,
  });

  final int built;
  final List<DateTime> failedDates;
  final bool stopped;
  final String? stopCode;
  final int? retryAfterSeconds;
}

/// Builds today through today + 6, one server call at a time.
class WeekGenerator {
  WeekGenerator({
    required this.createDay,
    required this.isLogged,
    required this.storeDay,
    DateTime Function()? now,
    this.wait = Future<void>.delayed,
  }) : _now = now ?? DateTime.now;

  final Future<DayPlan> Function(DateTime date) createDay;
  final Future<bool> Function(DateTime date) isLogged;
  final Future<void> Function(DayPlan plan) storeDay;
  final Future<void> Function(Duration duration) wait;
  final DateTime Function() _now;

  /// [fromTomorrow] leaves today as it is (a rebuild after a new target).
  Stream<WeekEvent> run({bool fromTomorrow = false}) async* {
    final dates = weekDates(_now()).skip(fromTomorrow ? 1 : 0);
    final failed = <DateTime>[];
    var built = 0;
    for (final date in dates) {
      if (await isLogged(date)) {
        continue;
      }
      yield WeekDateStarted(date);
      final outcome = await _oneDate(date);
      switch (outcome) {
        case _DateBuilt(:final plan):
          built += 1;
          yield WeekDateDone(plan);
        case _DateFailed(:final code):
          failed.add(date);
          yield WeekDateFailed(date, code);
        case _DateStopped(:final code, :final retryAfterSeconds):
          yield WeekFinished(
            built: built,
            failedDates: failed,
            stopped: true,
            stopCode: code,
            retryAfterSeconds: retryAfterSeconds,
          );
          return;
      }
    }
    yield WeekFinished(built: built, failedDates: failed, stopped: false);
  }

  Future<_DateOutcome> _oneDate(DateTime date) async {
    var attempts = 0;
    while (true) {
      attempts += 1;
      try {
        final plan = await createDay(date);
        await storeDay(plan);
        return _DateBuilt(plan);
      } on PlanRequestException catch (error) {
        if (error.network) {
          return const _DateStopped('NETWORK');
        }
        final code = error.code ?? 'UNEXPECTED';
        if (code == 'PLANNER_BUSY') {
          if (attempts >= 3) {
            return _DateStopped(
              code,
              retryAfterSeconds: error.retryAfterSeconds,
            );
          }
          await wait(Duration(seconds: _busyWait(error.retryAfterSeconds)));
          continue;
        }
        if (code == 'PLANNER_TIMEOUT' ||
            code == 'RATE_LIMITED' ||
            code == 'NOT_ELIGIBLE' ||
            code == 'NO_TARGET' ||
            code == 'PROFILE_NOT_FOUND') {
          return _DateStopped(code, retryAfterSeconds: error.retryAfterSeconds);
        }
        if (code == 'NO_FEASIBLE_PLAN' || code == 'CONDITION_CONFLICT') {
          return _DateFailed(code);
        }
        return _DateStopped(code, retryAfterSeconds: error.retryAfterSeconds);
      }
    }
  }
}

int _busyWait(int? retryAfter) {
  final seconds = retryAfter ?? 5;
  if (seconds < 0) {
    return 5;
  }
  if (seconds > 30) {
    return 30;
  }
  return seconds;
}

sealed class _DateOutcome {
  const _DateOutcome();
}

class _DateBuilt extends _DateOutcome {
  const _DateBuilt(this.plan);

  final DayPlan plan;
}

class _DateFailed extends _DateOutcome {
  const _DateFailed(this.code);

  final String code;
}

class _DateStopped extends _DateOutcome {
  const _DateStopped(this.code, {this.retryAfterSeconds});

  final String code;
  final int? retryAfterSeconds;
}
