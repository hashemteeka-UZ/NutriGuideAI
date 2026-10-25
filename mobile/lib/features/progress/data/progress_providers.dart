import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/network/dio_provider.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/data/user_context.dart';
import '../../plan/domain/plan_dates.dart';
import '../domain/progress.dart';
import 'progress_repository.dart';

final progressApiProvider = Provider<ProgressApi>((ref) {
  return ProgressApi(ref.watch(dioProvider));
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(progressApiProvider),
    now: ref.watch(planClockProvider),
  );
});

/// 0 is the week ending today; 1 the week before, up to [maxWeeksBack].
class WeekOffset extends Notifier<int> {
  @override
  int build() => 0;

  void older() {
    if (state < maxWeeksBack) {
      state += 1;
    }
  }

  void newer() {
    if (state > 0) {
      state -= 1;
    }
  }
}

final weekOffsetProvider = NotifierProvider<WeekOffset, int>(WeekOffset.new);

final weekDatesProvider = Provider<List<DateTime>>((ref) {
  return weekEnding(
    dateOnly(ref.watch(planClockProvider)()),
    ref.watch(weekOffsetProvider),
  );
});

final _weekDaysProvider = StreamProvider<Map<String, AdherenceDay>>((ref) {
  final dates = ref.watch(weekDatesProvider);
  return ref
      .watch(progressRepositoryProvider)
      .watchDays(isoDate(dates.first), isoDate(dates.last));
});

final _weekWaterProvider = StreamProvider<Map<String, int>>((ref) {
  final dates = ref.watch(weekDatesProvider);
  return ref
      .watch(progressRepositoryProvider)
      .watchWater(isoDate(dates.first), isoDate(dates.last));
});

final weekReportProvider = Provider<WeekReport>((ref) {
  final dates = ref.watch(weekDatesProvider);
  return weekReport(
    dates: <String>[for (final date in dates) isoDate(date)],
    days:
        ref.watch(_weekDaysProvider).asData?.value ??
        const <String, AdherenceDay>{},
    waterByDate:
        ref.watch(_weekWaterProvider).asData?.value ?? const <String, int>{},
  );
});

/// The current month for the calendar, keyed by date.
final monthDaysProvider = StreamProvider<Map<String, AdherenceDay>>((ref) {
  final today = dateOnly(ref.watch(planClockProvider)());
  final first = DateTime(today.year, today.month);
  final last = DateTime(today.year, today.month + 1, 0);
  return ref
      .watch(progressRepositoryProvider)
      .watchDays(isoDate(first), isoDate(last));
});

final streakProvider = StreamProvider<int?>((ref) {
  return ref.watch(progressRepositoryProvider).watchStreak();
});

/// 30 or 90 days of weights.
class WeightRange extends Notifier<int> {
  @override
  int build() => 30;

  void set(int days) => state = days == 90 ? 90 : 30;
}

final weightRangeProvider = NotifierProvider<WeightRange, int>(WeightRange.new);

final _weightPointsProvider = StreamProvider<List<WeightPointView>>((ref) {
  final today = dateOnly(ref.watch(planClockProvider)());
  final days = ref.watch(weightRangeProvider);
  final from = DateTime(today.year, today.month, today.day - (days - 1));
  return ref.watch(progressRepositoryProvider).watchWeights(isoDate(from));
});

final weightSummaryProvider = Provider<WeightSummary>((ref) {
  final user = ref.watch(userContextProvider);
  return weightSummary(
    points:
        ref.watch(_weightPointsProvider).asData?.value ??
        const <WeightPointView>[],
    goalType: user?.goalType,
    targetWeightKg: user?.targetWeightKg,
  );
});
