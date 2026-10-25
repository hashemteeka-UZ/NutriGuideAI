import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/meal_stance.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/personal_data.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/sync_api.dart';
import '../../../core/sync/sync_engine.dart';
import '../../catalog/data/catalog_sync.dart';
import '../../catalog/data/meal_pref_writer.dart';
import '../../plan/data/plan_mapper.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/data/plan_sync.dart';
import '../../progress/data/progress_providers.dart';
import '../../weight/data/weight_providers.dart';
import '../domain/logging.dart';
import 'interaction_queue.dart';
import 'logging_repository.dart';

final outboxStoreProvider = Provider<OutboxStore>((ref) {
  return OutboxStore(ref.watch(appDatabaseProvider));
});

final syncApiProvider = Provider<SyncApi>((ref) {
  return DioSyncApi(ref.watch(dioProvider));
});

final syncCursorProvider = Provider<SyncCursor>((ref) {
  return PreferencesSyncCursor();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final personal = ref.watch(personalDataStoreProvider);
  final engine = SyncEngine(
    database: ref.watch(appDatabaseProvider),
    outbox: ref.watch(outboxStoreProvider),
    api: ref.watch(syncApiProvider),
    cursor: ref.watch(syncCursorProvider),
    generation: () => personal.generation,
    hooks: SyncHooks(
      storePlans: (plans) async {
        final repository = ref.read(planRepositoryProvider);
        for (final plan in plans) {
          await repository.storeDay(dayPlanFromApi(plan));
        }
      },
      replacePrefs: (prefs) async {
        await personal.replacePrefs([
          for (final pref in prefs)
            if (pref.stance == MealStance.like ||
                pref.stance == MealStance.dislike)
              (
                mealId: pref.mealId,
                stance: pref.stance.json!,
                updatedAt: pref.updatedAt.toUtc(),
              ),
        ]);
        ref.read(mealRevisionProvider.notifier).bump();
      },
      profileChanged: () async {
        await ref.read(userContextRefreshProvider)();
        await ref
            .read(catalogSyncProvider)
            .sync(lang: ref.read(localeCodeProvider).code);
      },
      fullRefresh: () => ref.read(planSyncProvider).refresh(),
      todayChanged: () async {
        await ref
            .read(todayRepositoryProvider)
            .refreshDay(ref.read(planClockProvider)());
        // Logs changed: the Progress tab reads the new server days (#281).
        try {
          await ref.read(progressRepositoryProvider).refresh();
        } on Object {
          // The cached report stays until the next refresh.
        }
      },
      weightConfirmed: () => ref.read(targetRecheckProvider)(),
    ),
  );
  // A sync run knows as well as a plan refresh whether the server answers.
  void outcome() {
    final value = engine.lastOutcome.value;
    if (value == SyncOutcome.done) {
      ref.read(planOfflineProvider.notifier).setOffline(false);
    } else if (value == SyncOutcome.offline) {
      ref.read(planOfflineProvider.notifier).setOffline(true);
    }
  }

  engine.lastOutcome.addListener(outcome);
  ref.onDispose(() {
    engine.lastOutcome.removeListener(outcome);
    engine.uploading.dispose();
    engine.lastOutcome.dispose();
  });
  return engine;
});

/// Starts a sync shortly after a user action, or right away.
class SyncTrigger {
  SyncTrigger(this._engine, {this.delay = const Duration(seconds: 2)});

  final SyncEngine _engine;
  final Duration delay;
  Timer? _timer;

  /// Debounced: several taps in a row make one run.
  void soon() {
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(_engine.syncNow()));
  }

  Future<SyncOutcome> now() {
    _timer?.cancel();
    return _engine.syncNow();
  }

  void dispose() => _timer?.cancel();
}

final syncTriggerProvider = Provider<SyncTrigger>((ref) {
  final trigger = SyncTrigger(ref.watch(syncEngineProvider));
  ref.onDispose(trigger.dispose);
  return trigger;
});

final loggingRepositoryProvider = Provider<LoggingRepository>((ref) {
  return LoggingRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxStoreProvider),
    now: ref.watch(planClockProvider),
    onAction: () => ref.read(syncTriggerProvider).soon(),
  );
});

final interactionQueueProvider = Provider<InteractionQueue>((ref) {
  return InteractionQueue(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxStoreProvider),
  );
});

final dayLogsProvider = StreamProvider.family<List<LoggedMeal>, String>((
  ref,
  String date,
) {
  return ref.watch(loggingRepositoryProvider).watchDate(date);
});

final todayLogsProvider = Provider<List<LoggedMeal>>((ref) {
  final date = ref.watch(todayIsoProvider);
  return ref.watch(dayLogsProvider(date)).asData?.value ?? const [];
});

final outboxCountsProvider = StreamProvider<OutboxCounts>((ref) {
  return ref.watch(outboxStoreProvider).watchCounts();
});

final syncUploadingProvider = NotifierProvider<_ListenableBool, bool>(
  _ListenableBool.new,
);

class _ListenableBool extends Notifier<bool> {
  @override
  bool build() {
    final listenable = ref.watch(syncEngineProvider).uploading;
    void update() => state = listenable.value;
    listenable.addListener(update);
    ref.onDispose(() => listenable.removeListener(update));
    return listenable.value;
  }
}

final syncStatusProvider = Provider<SyncStatusView>((ref) {
  final counts =
      ref.watch(outboxCountsProvider).asData?.value ?? OutboxCounts.empty;
  return SyncStatusView(
    uploading: ref.watch(syncUploadingProvider),
    pending: counts.pending,
    rejected: counts.rejected,
  );
});

final rejectedLogsProvider = FutureProvider<List<RejectedLog>>((ref) {
  ref.watch(outboxCountsProvider);
  return ref.watch(loggingRepositoryProvider).rejectedLogs();
});

/// Logout sends what is queued first (Decision #263). The function returns
/// true when nothing is left on the phone.
final uploadBeforeLogoutProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    try {
      await ref.read(syncTriggerProvider).now();
    } on Object {
      // Counted below.
    }
    final counts = await ref.read(outboxStoreProvider).counts();
    return counts.pending == 0 && counts.rejected == 0;
  };
});
