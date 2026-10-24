import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/app/app.dart';
import 'package:nutriguide/core/network/app_failure.dart';
import 'package:nutriguide/core/theme/motion.dart';
import 'package:nutriguide/features/auth/data/auth_repository_impl.dart';
import 'package:nutriguide/features/auth/data/token_store.dart';
import 'package:nutriguide/features/server_check/data/server_check_repository.dart';
import 'package:nutriguide/features/server_check/domain/server_status.dart';
import 'package:nutriguide/features/server_check/presentation/server_check_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/memory_secure.dart';

void main() {
  testWidgets('shows a loading indicator in Arabic RTL', (tester) async {
    final pending = Completer<ServerStatus>();
    addTearDown(() {
      if (!pending.isCompleted) {
        pending.complete(_connected);
      }
    });
    await _pumpApp(
      tester,
      _ScriptedRepository(<Future<ServerStatus> Function()>[
        () => pending.future,
      ]),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('الخادم متصل'), findsNothing);
    expect(_directionOf(tester), TextDirection.rtl);
  });

  testWidgets('shows the connected server in Arabic RTL', (tester) async {
    await _pumpApp(
      tester,
      _ScriptedRepository(<Future<ServerStatus> Function()>[
        () async => _connected,
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('الخادم متصل'), findsOneWidget);
    expect(find.textContaining('1.0.0'), findsOneWidget);
    expect(find.textContaining('catalog_v3'), findsOneWidget);
    expect(find.textContaining('cpsat'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.textContaining('10.0.2.2:8000'), findsOneWidget);
    expect(_directionOf(tester), TextDirection.rtl);
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).duration,
      const Duration(milliseconds: 350),
    );
  });

  testWidgets('shows the failure message and retries', (tester) async {
    final repository = _ScriptedRepository(<Future<ServerStatus> Function()>[
      () async => throw const NetworkUnavailable(),
      () async => _connected,
    ]);
    await _pumpApp(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد اتصال بالخادم.'), findsOneWidget);
    expect(_directionOf(tester), TextDirection.rtl);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.text('الخادم متصل'), findsOneWidget);
  });

  testWidgets('asks for an update when the API major is not 1', (tester) async {
    await _pumpApp(
      tester,
      _ScriptedRepository(<Future<ServerStatus> Function()>[
        () async => const ServerStatus(
          apiVersion: '2.0.0',
          datasetVersion: 'catalog_v3',
          plannerName: 'cpsat',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('التطبيق يحتاج تحديثًا'), findsOneWidget);
    expect(find.text('الخادم متصل'), findsNothing);
    expect(find.textContaining('2.0.0'), findsOneWidget);
    expect(_directionOf(tester), TextDirection.rtl);
  });

  testWidgets('skips the status icon fade when motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (int retryCount, Object error) => null,
        overrides: [
          serverCheckRepositoryProvider.overrideWithValue(
            _ScriptedRepository(<Future<ServerStatus> Function()>[
              () async => _connected,
            ]),
          ),
        ],
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: _DirectionProbe(),
        ),
      ),
    );
    await tester.pump();

    expect(
      animationsEnabled(tester.element(find.byType(_DirectionProbe))),
      isFalse,
    );
  });
}

const _connected = ServerStatus(
  apiVersion: '1.0.0',
  datasetVersion: 'catalog_v3',
  plannerName: 'cpsat',
);

class _DirectionProbe extends StatelessWidget {
  const _DirectionProbe();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class _ScriptedRepository implements ServerCheckRepository {
  _ScriptedRepository(this._handlers);

  final List<Future<ServerStatus> Function()> _handlers;
  int calls = 0;

  @override
  Future<ServerStatus> load() {
    final handler = _handlers[calls];
    calls += 1;
    return handler();
  }
}

Future<void> _pumpApp(
  WidgetTester tester,
  ServerCheckRepository repository,
) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int retryCount, Object error) => null,
      overrides: [
        serverCheckRepositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        tokenStoreProvider.overrideWithValue(SecureTokenStore(MemorySecure())),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('debug-server-check')));
  await tester.pump();
  // Welcome needed reduced motion so its auto-advance timer could settle.
  // The server check screen itself is measured with motion enabled.
  tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
}

TextDirection _directionOf(WidgetTester tester) {
  return Directionality.of(tester.element(find.byType(ServerCheckScreen)));
}
