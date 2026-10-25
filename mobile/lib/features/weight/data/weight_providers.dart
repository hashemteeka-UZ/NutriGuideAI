import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/network/dio_provider.dart';
import '../../logging/data/logging_providers.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/data/user_context.dart';
import '../domain/weight.dart';
import 'weight_repository.dart';

final weightApiProvider = Provider<WeightApi>((ref) {
  return WeightApi(ref.watch(dioProvider));
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxStoreProvider),
    ref.watch(weightApiProvider),
    now: ref.watch(planClockProvider),
    onAction: () => ref.read(syncTriggerProvider).soon(),
  );
});

final latestWeightProvider = StreamProvider<StoredWeight?>((ref) {
  return ref.watch(weightRepositoryProvider).watchLatest();
});

/// True when a new daily target should be announced (#275). Today shows the
/// notice; «لاحقًا» or a rebuild clears it.
class TargetNotice extends Notifier<bool> {
  @override
  bool build() => false;

  void show() => state = true;

  void dismiss() => state = false;
}

final targetNoticeProvider = NotifierProvider<TargetNotice, bool>(
  TargetNotice.new,
);

/// Refetches the targets and raises the notice when the target id changed.
final targetRecheckProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final before = ref.read(userContextProvider)?.target?.targetId;
    await ref.read(userContextRefreshProvider)();
    final after = ref.read(userContextProvider)?.target?.targetId;
    if (before != null && after != null && before != after) {
      ref.read(targetNoticeProvider.notifier).show();
    }
  };
});
