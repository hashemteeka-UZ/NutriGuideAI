import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/app/app.dart';
import 'package:nutriguide/core/locale/locale_controller.dart';
import 'package:nutriguide/features/auth/data/auth_repository_impl.dart';
import 'package:nutriguide/features/auth/data/token_store.dart';
import 'package:nutriguide/features/auth/domain/auth_repository.dart';
import 'package:nutriguide/features/catalog/data/catalog_sync.dart';
import 'package:nutriguide/features/profile/data/device_timezone.dart';
import 'package:nutriguide/features/profile/data/profile_repository.dart';
import 'package:nutriguide/features/profile/domain/profile_repository.dart';
import 'package:nutriguide/features/profile/presentation/onboarding_controller.dart';
import 'package:nutriguide/features/reference/data/reference_repository.dart';
import 'package:nutriguide/features/reference/domain/reference_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'memory_secure.dart';
import 'onboarding_fakes.dart';

Future<void> pumpNutriguide(
  WidgetTester tester, {
  required AuthRepository auth,
  Size? logicalSize,
  double textScale = 1,
  ProfileRepository? profile,
  ReferenceRepository? reference,
  DateTime Function()? now,
  String? storedLocale,
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
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}
