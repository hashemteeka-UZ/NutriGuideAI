import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/network/dio_provider.dart';
import '../../logging/data/logging_providers.dart';
import '../../plan/data/plan_providers.dart';
import '../domain/water.dart';
import 'water_api.dart';
import 'water_repository.dart';

final waterApiProvider = Provider<WaterApi>((ref) {
  return WaterApi(ref.watch(dioProvider));
});

final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return WaterRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxStoreProvider),
    ref.watch(waterApiProvider),
    now: ref.watch(planClockProvider),
    onAction: () => ref.read(syncTriggerProvider).soon(),
  );
});

final todayWaterEntriesProvider = StreamProvider<List<WaterEntry>>((ref) {
  return ref
      .watch(waterRepositoryProvider)
      .watchDate(ref.watch(todayIsoProvider));
});

/// Today's water for the Water tab and the Today card (one source).
final todayWaterProvider = Provider<WaterView>((ref) {
  return waterView(
    ref.watch(todaySummaryProvider).asData?.value,
    ref.watch(todayWaterEntriesProvider).asData?.value ?? const <WaterEntry>[],
  );
});
