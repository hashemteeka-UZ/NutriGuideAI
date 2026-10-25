import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/plan.dart';
import 'plan_providers.dart';
import 'plan_repository.dart';

abstract interface class PlanSync {
  Future<void> refresh({bool resume = false});
}

class DioPlanSync implements PlanSync {
  DioPlanSync({
    required this.plans,
    required this.today,
    required this.refreshUser,
    required this.now,
    required this.onOffline,
  });

  final PlanRepository plans;
  final TodayRepository today;
  final Future<void> Function() refreshUser;
  final DateTime Function() now;
  final void Function(bool offline) onOffline;
  DateTime? _lastResume;

  @override
  Future<void> refresh({bool resume = false}) async {
    if (resume) {
      final clock = now();
      final last = _lastResume;
      if (last != null && clock.difference(last) < const Duration(minutes: 5)) {
        return;
      }
      _lastResume = clock;
    }
    try {
      await Future.wait<void>(<Future<void>>[
        plans.refresh(),
        today.refreshDay(now()),
        refreshUser(),
      ]);
      onOffline(false);
    } on PlanRequestException catch (error) {
      if (error.network) {
        onOffline(true);
      }
    }
  }
}

class NoopPlanSync implements PlanSync {
  const NoopPlanSync();

  @override
  Future<void> refresh({bool resume = false}) async {}
}

final planSyncProvider = Provider<PlanSync>((ref) {
  return DioPlanSync(
    plans: ref.watch(planRepositoryProvider),
    today: ref.watch(todayRepositoryProvider),
    refreshUser: ref.watch(userContextRefreshProvider),
    now: ref.watch(planClockProvider),
    onOffline: (bool offline) {
      ref.read(planOfflineProvider.notifier).setOffline(offline);
    },
  );
});
