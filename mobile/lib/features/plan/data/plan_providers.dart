import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/network/dio_provider.dart';
import '../../reference/data/reference_repository.dart';
import '../domain/plan.dart';
import '../domain/plan_dates.dart';
import '../domain/week_generator.dart';
import 'plan_api.dart';
import 'plan_repository.dart';
import 'user_context.dart';

final planClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final planApiProvider = Provider<PlanApi>((ref) {
  return PlanApi(ref.watch(dioProvider));
});

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  final locale = ref.watch(localeCodeProvider);
  return PlanRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(planApiProvider),
    locale: () => locale.code,
    now: ref.watch(planClockProvider),
  );
});

final todayRepositoryProvider = Provider<TodayRepository>((ref) {
  return TodayRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(planApiProvider),
    ref.watch(planRepositoryProvider),
    now: ref.watch(planClockProvider),
  );
});

final weekGeneratorProvider = Provider<WeekGenerator>((ref) {
  final plans = ref.watch(planRepositoryProvider);
  final api = ref.watch(planApiProvider);
  return WeekGenerator(
    createDay: api.createDay,
    isLogged: plans.dayHasLoggedItem,
    storeDay: plans.storeDay,
    now: ref.watch(planClockProvider),
  );
});

final weekPlansProvider = StreamProvider<List<DayPlan>>((ref) {
  ref.watch(localeProvider);
  final clock = ref.watch(planClockProvider);
  final range = planCacheRange(clock());
  return ref
      .watch(planRepositoryProvider)
      .watchRange(isoDate(range.from), isoDate(range.to));
});

class PlanOfflineController extends Notifier<bool> {
  @override
  bool build() => false;

  void setOffline(bool value) {
    if (state != value) {
      state = value;
    }
  }
}

final planOfflineProvider = NotifierProvider<PlanOfflineController, bool>(
  PlanOfflineController.new,
);

class SelectedPlanDate extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String date) {
    state = date;
  }
}

final selectedPlanDateProvider = NotifierProvider<SelectedPlanDate, String?>(
  SelectedPlanDate.new,
);

class LaunchShowcase extends Notifier<bool> {
  @override
  bool build() => false;

  void open() {
    state = true;
  }

  void close() {
    state = false;
  }
}

final launchShowcaseProvider = NotifierProvider<LaunchShowcase, bool>(
  LaunchShowcase.new,
);

final userContextRefreshProvider = Provider<Future<void> Function()>((ref) {
  final dio = ref.watch(dioProvider);
  return () => ref.read(userContextProvider.notifier).refresh(dio);
});

class RecheckOnboarding extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;

  void close() => state = false;
}

final recheckOnboardingProvider = NotifierProvider<RecheckOnboarding, bool>(
  RecheckOnboarding.new,
);

final todayIsoProvider = Provider<String>((ref) {
  return isoDate(dateOnly(ref.watch(planClockProvider)()));
});

final todayPlanProvider = StreamProvider<DayPlan?>((ref) {
  // Meal names come from the catalog of the current language.
  ref.watch(localeProvider);
  return ref
      .watch(planRepositoryProvider)
      .watchDay(ref.watch(todayIsoProvider));
});

final todaySummaryProvider = StreamProvider<DaySummary?>((ref) {
  return ref
      .watch(todayRepositoryProvider)
      .watchSummary(ref.watch(todayIsoProvider));
});

final todayWindowsProvider = StreamProvider<List<MealWindowSpan>>((ref) {
  return ref
      .watch(todayRepositoryProvider)
      .watchWindows(ref.watch(todayIsoProvider));
});

final selectedDayPlanProvider = StreamProvider<DayPlan?>((ref) {
  ref.watch(localeProvider);
  final String date =
      ref.watch(selectedPlanDateProvider) ?? ref.watch(todayIsoProvider);
  return ref.watch(planRepositoryProvider).watchDay(date);
});

final selectedWindowsProvider = StreamProvider<List<MealWindowSpan>>((ref) {
  final String date =
      ref.watch(selectedPlanDateProvider) ?? ref.watch(todayIsoProvider);
  return ref.watch(todayRepositoryProvider).watchWindows(date);
});

final planItemProvider = StreamProvider.family<PlanItem?, int>((ref, int id) {
  ref.watch(localeProvider);
  return ref.watch(planRepositoryProvider).watchItem(id);
});

final conditionNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final locale = ref.watch(localeProvider);
  final data = await ref
      .watch(referenceRepositoryProvider)
      .load(locale: locale.languageCode);
  return <String, String>{
    for (final condition in data.conditions) condition.code: condition.name,
  };
});
