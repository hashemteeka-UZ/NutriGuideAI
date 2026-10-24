import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/app/app.dart';
import 'package:nutriguide/features/auth/data/auth_repository_impl.dart';
import 'package:nutriguide/features/auth/data/token_store.dart';
import 'package:nutriguide/features/auth/domain/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'memory_secure.dart';

Future<void> pumpNutriguide(
  WidgetTester tester, {
  required AuthRepository auth,
  Size? logicalSize,
  double textScale = 1,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
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
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}
