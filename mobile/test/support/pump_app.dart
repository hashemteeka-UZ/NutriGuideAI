import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/app/app.dart';
import 'package:nutriguide/core/api/generated/models/adherence_range_out.dart';
import 'package:nutriguide/core/api/generated/models/sync_changes.dart';
import 'package:nutriguide/core/api/generated/models/water_day.dart';
import 'package:nutriguide/core/api/generated/models/weight_out.dart';
import 'package:nutriguide/core/api/generated/models/weight_point.dart';
import 'package:nutriguide/core/api/manual/sync_models.dart';
import 'package:nutriguide/core/db/app_database.dart' hide PlanItem;
import 'package:nutriguide/core/db/database_provider.dart';
import 'package:nutriguide/core/locale/locale_controller.dart';
import 'package:nutriguide/core/sync/sync_api.dart';
import 'package:nutriguide/features/auth/data/auth_repository_impl.dart';
import 'package:nutriguide/features/auth/data/token_store.dart';
import 'package:nutriguide/features/auth/domain/auth_repository.dart';
import 'package:nutriguide/features/catalog/data/catalog_sync.dart';
import 'package:nutriguide/features/logging/data/logging_providers.dart';
import 'package:nutriguide/features/logging/presentation/sync_lifecycle.dart';
import 'package:nutriguide/features/plan/data/plan_api.dart';
import 'package:nutriguide/features/plan/data/plan_providers.dart';
import 'package:nutriguide/features/plan/data/plan_sync.dart';
import 'package:nutriguide/features/plan/domain/plan.dart';
import 'package:nutriguide/features/profile/data/device_timezone.dart';
import 'package:nutriguide/features/profile/data/profile_repository.dart';
import 'package:nutriguide/features/profile/domain/profile_repository.dart';
import 'package:nutriguide/features/profile/presentation/onboarding_controller.dart';
import 'package:nutriguide/features/progress/data/progress_providers.dart';
import 'package:nutriguide/features/progress/data/progress_repository.dart';
import 'package:nutriguide/features/reference/data/reference_repository.dart';
import 'package:nutriguide/features/reference/domain/reference_data.dart';
import 'package:nutriguide/features/shopping/domain/shopping.dart';
import 'package:nutriguide/features/water/data/water_api.dart';
import 'package:nutriguide/features/water/data/water_providers.dart';
import 'package:nutriguide/features/water/domain/water.dart';
import 'package:nutriguide/features/weight/data/weight_providers.dart';
import 'package:nutriguide/features/weight/data/weight_repository.dart';
import 'package:nutriguide/features/weight/domain/weight.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'memory_secure.dart';
import 'onboarding_fakes.dart';

/// Widget tests that mount the app. Drift arms a zero-length timer when a
/// watched query is cancelled, and Flutter checks for pending timers before
/// `addTearDown` runs, so the tree is disposed here, inside the test body.
void testNutriguide(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (WidgetTester tester) async {
    Object? failure;
    StackTrace? stack;
    try {
      await body(tester);
    } on Object catch (error, trace) {
      failure = error;
      stack = trace;
    }
    Object? flushFailure;
    try {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
    } on Object catch (error) {
      flushFailure = error;
    }
    if (failure != null) {
      Error.throwWithStackTrace(failure, stack ?? StackTrace.current);
    }
    if (flushFailure != null) {
      throw flushFailure;
    }
  });
}

Future<void> pumpNutriguide(
  WidgetTester tester, {
  required AuthRepository auth,
  Size? logicalSize,
  double textScale = 1,
  ProfileRepository? profile,
  ReferenceRepository? reference,
  DateTime Function()? now,
  String? storedLocale,
  AppDatabase? database,
  PlanApi? planApi,
  SyncApi? syncApi,
  WaterApi? waterApi,
  WeightApi? weightApi,
  ProgressApi? progressApi,
  List<Override> extra = const <Override>[],
}) async {
  SharedPreferences.setMockInitialValues(
    storedLocale == null
        ? <String, Object>{}
        : <String, Object>{localePreferenceKey: storedLocale},
  );
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (logicalSize != null) {
    tester.view.physicalSize = logicalSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final db = database ?? AppDatabase(NativeDatabase.memory());
  final ownsDatabase = database == null;
  if (ownsDatabase) {
    addTearDown(db.close);
  }
  await tester.pumpWidget(
    ProviderScope(
      retry: (int retryCount, Object error) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        tokenStoreProvider.overrideWithValue(SecureTokenStore(MemorySecure())),
        referenceRepositoryProvider.overrideWithValue(
          reference ?? FakeReferenceRepository(sampleReference),
        ),
        profileRepositoryProvider.overrideWithValue(
          profile ?? FakeProfileRepository(),
        ),
        catalogSyncProvider.overrideWithValue(const NoopCatalogSync()),
        timezoneSourceProvider.overrideWithValue(FakeTimezone('Asia/Riyadh')),
        onboardingNowProvider.overrideWithValue(
          now ?? () => DateTime.utc(2026, 10, 24),
        ),
        appDatabaseProvider.overrideWithValue(db),
        planSyncProvider.overrideWithValue(const NoopPlanSync()),
        planApiProvider.overrideWithValue(planApi ?? SilentPlanApi()),
        syncLifecycleProvider.overrideWithValue(null),
        syncApiProvider.overrideWithValue(syncApi ?? OfflineSyncApi()),
        waterApiProvider.overrideWithValue(waterApi ?? OfflineWaterApi()),
        userContextRefreshProvider.overrideWithValue(() async {}),
        progressApiProvider.overrideWithValue(
          progressApi ?? OfflineProgressApi(),
        ),
        weightApiProvider.overrideWithValue(weightApi ?? OfflineWeightApi()),
        ...extra,
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Sync calls from widget tests behave like a phone with no connection.
class OfflineSyncApi implements SyncApi {
  int uploads = 0;

  @override
  Future<SyncBatchResult> upload(List<Map<String, Object?>> operations) async {
    uploads += 1;
    throw const SyncFailure(SyncFailureKind.transient);
  }

  @override
  Future<SyncChanges> changes(DateTime since) async {
    throw const SyncFailure(SyncFailureKind.transient);
  }
}

/// Water calls from widget tests behave like a phone with no connection.
class OfflineWaterApi extends WaterApi {
  OfflineWaterApi() : super(Dio());

  @override
  Future<WaterDay> day(DateTime date) async {
    throw const WaterException('NETWORK', network: true);
  }

  @override
  Future<void> setGoal(int goalMl) async {
    throw const WaterException('NETWORK', network: true);
  }
}

/// Progress calls from widget tests behave like a phone with no connection.
class OfflineProgressApi extends ProgressApi {
  OfflineProgressApi() : super(Dio());

  @override
  Future<AdherenceRangeOut> adherence(DateTime from, DateTime to) async {
    throw const ProgressException('NETWORK', network: true);
  }

  @override
  Future<List<WeightPoint>> weights(DateTime from, DateTime to) async {
    throw const ProgressException('NETWORK', network: true);
  }
}

/// Weight calls from widget tests behave like a phone with no connection.
class OfflineWeightApi extends WeightApi {
  OfflineWeightApi() : super(Dio());

  @override
  Future<WeightOut> put({
    required String measuredOn,
    required double weightKg,
    required DateTime updatedAt,
  }) async {
    throw const WeightException('NETWORK');
  }
}

/// Plan calls from widget tests fail closed instead of touching the network.
class SilentPlanApi extends PlanApi {
  SilentPlanApi() : super(Dio());

  @override
  Future<DayPlan> createDay(DateTime date) async {
    throw const PlanRequestException(network: true);
  }

  @override
  Future<List<DayPlan>> listPlans({
    required DateTime from,
    required DateTime to,
  }) async {
    throw const PlanRequestException(network: true);
  }

  @override
  Future<DayDetail> fetchDay(DateTime date) async {
    throw const PlanRequestException(network: true);
  }

  @override
  Future<List<PlanAlternative>> alternatives(int planItemId) async {
    throw const PlanRequestException(network: true);
  }

  @override
  Future<PlanItem> swap({required int planItemId, required int mealId}) async {
    throw const PlanRequestException(network: true);
  }

  @override
  Future<List<ShoppingRow>> shopping({
    required DateTime from,
    required DateTime to,
  }) async {
    throw const PlanRequestException(network: true);
  }
}
