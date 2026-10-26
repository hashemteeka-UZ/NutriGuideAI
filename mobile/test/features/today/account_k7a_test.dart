import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/manual/sync_models.dart';
import 'package:nutriguide/core/config/app_version.dart';
import 'package:nutriguide/core/db/app_database.dart' hide PlanItem;
import 'package:nutriguide/core/network/app_failure.dart';
import 'package:nutriguide/core/sync/outbox_store.dart';
import 'package:nutriguide/core/theme/theme_mode_controller.dart';
import 'package:nutriguide/features/auth/data/account_deleter.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/pump_app.dart';

class _FakeDeleter implements AccountDeleter {
  _FakeDeleter({this.error});

  final Object? error;
  int calls = 0;

  @override
  Future<void> delete() async {
    calls += 1;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
  }
}

void main() {
  test('appVersion follows pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(appVersion, match!.group(1));
  });

  test('theme names map to ThemeMode and persist (#310)', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    expect(themeModeFromName('dark'), ThemeMode.dark);
    expect(themeModeFromName('light'), ThemeMode.light);
    expect(themeModeFromName(null), ThemeMode.system);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(themeModeProvider);
    await container.read(themeModeProvider.notifier).select(ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(themePreferenceKey), 'dark');

    final again = ProviderContainer();
    addTearDown(again.dispose);
    again.read(themeModeProvider);
    await Future<void>.delayed(Duration.zero);
    expect(again.read(themeModeProvider), ThemeMode.dark);
  });

  Future<void> openMe(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tab-me')));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(
      find.byKey(key),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('account-screen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  testNutriguide('appearance sheet applies dark mode', (tester) async {
    await pumpNutriguide(tester, auth: _signedIn());
    await openMe(tester);
    await tester.tap(find.byKey(const Key('account-appearance')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme-dark')));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testNutriguide('about: both languages, with the version (#312)', (
    tester,
  ) async {
    await pumpNutriguide(tester, auth: _signedIn());
    await openMe(tester);
    await reveal(tester, const Key('account-about'));
    await tester.tap(find.byKey(const Key('account-about')));
    await tester.pumpAndSettle();
    // The version and the English name sit in isolates so RTL keeps their
    // order and the final period (#315).
    final version = tester.widget<Text>(
      find.byKey(const Key('about-version-number')),
    );
    expect(version.data, appVersion);
    expect(version.textDirection, TextDirection.ltr);
    expect(find.text('الإصدار'), findsOneWidget);
    expect(
      find.textContaining('\u2066USDA FoodData Central\u2069.'),
      findsOneWidget,
    );
    expect(find.text('كيف يتعلّم التطبيق منك'), findsOneWidget);
    expect(find.textContaining('USDA FoodData Central'), findsOneWidget);
  });

  testNutriguide('about in English', (tester) async {
    await pumpNutriguide(tester, auth: _signedIn(), storedLocale: 'en');
    await openMe(tester);
    await reveal(tester, const Key('account-about'));
    await tester.tap(find.byKey(const Key('account-about')));
    await tester.pumpAndSettle();
    expect(find.text('Version'), findsOneWidget);
    expect(find.text(appVersion), findsOneWidget);
    expect(find.text('How the app learns from you'), findsOneWidget);
  });

  Future<AppDatabase> withPending() async {
    final database = AppDatabase(NativeDatabase.memory());
    await OutboxStore(database).enqueue(
      const InteractionCreateOp(
        opId: 'op-1',
        clientUuid: 'u-1',
        mealId: 1,
        eventType: 'VIEW',
      ),
    );
    return database;
  }

  testNutriguide('delete: disabled until the word, then wipes and signs out', (
    tester,
  ) async {
    final database = await withPending();
    addTearDown(database.close);
    final auth = _signedIn();
    final deleter = _FakeDeleter();
    await pumpNutriguide(
      tester,
      auth: auth,
      database: database,
      extra: <Override>[accountDeleterProvider.overrideWithValue(deleter)],
    );
    await openMe(tester);
    await reveal(tester, const Key('account-delete'));
    await tester.tap(find.byKey(const Key('account-delete')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delete-pending')), findsOneWidget);
    FilledButton button() =>
        tester.widget<FilledButton>(find.byKey(const Key('delete-confirm')));
    expect(button().onPressed, isNull);
    await tester.enterText(find.byKey(const Key('delete-word')), 'حذ');
    await tester.pump();
    expect(button().onPressed, isNull);
    await tester.enterText(find.byKey(const Key('delete-word')), 'حذف');
    await tester.pump();
    expect(button().onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('delete-confirm')));
    await tester.pumpAndSettle();
    expect(deleter.calls, 1);
    expect(auth.logoutCalls, 1);
    expect(find.byKey(const Key('delete-account-screen')), findsNothing);
    expect(find.text('حُذف حسابك وكل بياناتك'), findsOneWidget);
  });

  testNutriguide('delete: a failure keeps everything', (tester) async {
    final database = await withPending();
    addTearDown(database.close);
    final auth = _signedIn();
    final deleter = _FakeDeleter(error: const NetworkUnavailable());
    await pumpNutriguide(
      tester,
      auth: auth,
      database: database,
      extra: <Override>[accountDeleterProvider.overrideWithValue(deleter)],
    );
    await openMe(tester);
    await reveal(tester, const Key('account-delete'));
    await tester.tap(find.byKey(const Key('account-delete')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('delete-word')), 'حذف');
    await tester.pump();
    await tester.tap(find.byKey(const Key('delete-confirm')));
    await tester.pumpAndSettle();
    expect(deleter.calls, 1);
    expect(auth.logoutCalls, 0);
    expect(find.byKey(const Key('delete-failed')), findsOneWidget);
    expect(find.byKey(const Key('delete-account-screen')), findsOneWidget);
    expect(await database.select(database.outbox).get(), hasLength(1));
  });
}

FakeAuthRepository _signedIn() {
  return FakeAuthRepository(
    restored: const SignedIn(
      account: AccountInfo(hasProfile: true, email: 'a@b.co'),
    ),
  );
}
