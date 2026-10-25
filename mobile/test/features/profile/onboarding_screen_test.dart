import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:nutriguide/core/l10n/app_localizations.dart';
import 'package:nutriguide/core/network/app_failure.dart';
import 'package:nutriguide/core/theme/app_theme.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/profile/domain/profile_repository.dart';
import 'package:nutriguide/features/profile/domain/profile_result.dart';
import 'package:nutriguide/features/profile/presentation/how_calculated_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/onboarding_fakes.dart';
import '../../support/pump_app.dart';

void main() {
  testNutriguide(
    'happy path reaches the result and keeps answers out of preferences',
    (tester) async {
      final profile = FakeProfileRepository(
        outcome: ProfileSaveOutcome(
          result: sampleResult(floorApplied: true),
          usedUtcFallback: false,
        ),
      );
      final auth = FakeAuthRepository(
        restored: const SignedIn(account: AccountInfo(hasProfile: false)),
      );
      await pumpNutriguide(tester, auth: auth, profile: profile);

      expect(find.text('عرّفنا بنفسك'), findsOneWidget);
      await tester.tap(find.byKey(const Key('onb-sex-FEMALE')));
      await tester.pump();
      await _next(tester);
      await _next(tester);

      expect(find.text('ما هدفكِ؟'), findsOneWidget);
      await tester.tap(find.byKey(const Key('onb-goal-LOSE')));
      await tester.pump();
      await _next(tester);
      await _next(tester);
      await tester.tap(find.byKey(const Key('onb-activity-LIGHT')));
      await tester.pump();
      await _next(tester);
      await tester.tap(find.byKey(const Key('onb-care-NONE')));
      await tester.pump();
      await _next(tester);

      expect(
        find.byKey(const Key('allergen-icon-ZZZ-fork-and-knife')),
        findsOneWidget,
      );
      await _next(tester);
      await _next(tester);

      expect(find.byKey(const Key('onb-kcal')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('onb-how')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onb-how')));
      await tester.pumpAndSettle();

      final factor = NumberFormat.decimalPatternDigits(
        locale: 'ar',
        decimalDigits: 3,
      ).format(2325 / 1500);
      expect(find.textContaining(factor), findsWidgets);
      expect(find.byKey(const Key('calc-resting')), findsOneWidget);
      expect(find.byKey(const Key('calc-activity')), findsOneWidget);
      expect(find.byKey(const Key('calc-adjustment')), findsOneWidget);
      expect(find.byKey(const Key('calc-floor')), findsOneWidget);
      expect(find.byKey(const Key('calc-daily')), findsOneWidget);

      Navigator.of(tester.element(find.byKey(const Key('calc-floor')))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onb-finish')));
      await tester.pumpAndSettle();

      expect(find.text('نبني خطتك الآن'), findsOneWidget);
      expect(profile.calls, 1);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    },
  );

  testNutriguide('the floor line is hidden when the server did not apply it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HowCalculatedSheet(
            goalType: 'LOSE',
            lines: calculationLines(target: sampleTarget(), goalType: 'LOSE'),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('calc-floor')), findsNothing);
    expect(find.byKey(const Key('calc-activity')), findsOneWidget);
    expect(find.byKey(const Key('calc-adjustment')), findsOneWidget);
  });

  testNutriguide('insulin answers open the general mode', (tester) async {
    final profile = FakeProfileRepository(
      outcome: ProfileSaveOutcome(
        result: sampleResult(
          eligible: false,
          reasons: const <String>['UNSUPPORTED_CONDITION:DIABETES_INSULIN'],
          waterMl: null,
        ),
        usedUtcFallback: false,
      ),
    );
    await pumpNutriguide(
      tester,
      auth: FakeAuthRepository(
        restored: const SignedIn(account: AccountInfo(hasProfile: false)),
      ),
      profile: profile,
    );

    await tester.tap(find.byKey(const Key('onb-sex-MALE')));
    await tester.pump();
    await _next(tester);
    await _next(tester);
    await tester.tap(find.byKey(const Key('onb-goal-MAINTAIN')));
    await tester.pump();
    await _next(tester);
    await tester.tap(find.byKey(const Key('onb-activity-SEDENTARY')));
    await tester.pump();
    await _next(tester);
    await tester.ensureVisible(find.byKey(const Key('onb-care-DIABETES_T2')));
    await tester.tap(find.byKey(const Key('onb-care-DIABETES_T2')));
    await tester.pump();
    await _next(tester);
    await _next(tester);
    await tester.tap(find.byKey(const Key('onb-insulin-yes')));
    await tester.pump();
    await _next(tester);
    await _next(tester);

    expect(find.byKey(const Key('onb-general')), findsOneWidget);
    expect(
      find.text('استخدام الإنسولين يحتاج تخطيطًا مع طبيبك لا يغطيه التطبيق'),
      findsOneWidget,
    );
    expect(profile.lastDraft?.insulin, isTrue);
  });

  testNutriguide('an under-18 reason shows the adults message', (tester) async {
    await pumpNutriguide(
      tester,
      auth: FakeAuthRepository(
        restored: const SignedIn(account: AccountInfo(hasProfile: false)),
      ),
      profile: FakeProfileRepository(
        outcome: ProfileSaveOutcome(
          result: sampleResult(
            eligible: false,
            reasons: const <String>['UNDER_18'],
            waterMl: null,
          ),
          usedUtcFallback: false,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('onb-sex-MALE')));
    await tester.pump();
    await _next(tester);
    await _next(tester);
    await tester.tap(find.byKey(const Key('onb-goal-MAINTAIN')));
    await tester.pump();
    await _next(tester);
    await tester.tap(find.byKey(const Key('onb-activity-SEDENTARY')));
    await tester.pump();
    await _next(tester);
    await tester.ensureVisible(find.byKey(const Key('onb-care-NONE')));
    await tester.tap(find.byKey(const Key('onb-care-NONE')));
    await tester.pump();
    await _next(tester);
    await _next(tester);
    await _next(tester);

    expect(find.text('الخطة الشخصية مخصصة للبالغين'), findsOneWidget);
    expect(find.text('ادخل التطبيق'), findsOneWidget);
  });

  testNutriguide('back returns to the previous step and keeps the answer', (
    tester,
  ) async {
    await pumpNutriguide(
      tester,
      auth: FakeAuthRepository(
        restored: const SignedIn(account: AccountInfo(hasProfile: false)),
      ),
    );

    await tester.tap(find.byKey(const Key('onb-sex-FEMALE')));
    await tester.pump();
    await _next(tester);
    expect(find.text('الطول والوزن'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onb-back')));
    await tester.pumpAndSettle();

    expect(find.text('عرّفنا بنفسك'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const Key('onb-sex-FEMALE')),
    );
    expect(semantics.label, contains('أنثى'));
    expect(semantics.flagsCollection.isSelected.name, 'isTrue');
    expect(semantics.flagsCollection.isButton, isTrue);
  });

  testNutriguide('english at text scale 1.3 lays out without overflow', (
    tester,
  ) async {
    await pumpNutriguide(
      tester,
      auth: FakeAuthRepository(
        restored: const SignedIn(account: AccountInfo(hasProfile: false)),
      ),
      logicalSize: const Size(360, 800),
      textScale: 1.3,
      storedLocale: 'en',
    );

    expect(find.text('Tell us about you'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onb-sex-FEMALE')));
    await tester.pump();
    await _next(tester);
    expect(find.text('Height and weight'), findsOneWidget);
    await _next(tester);
    expect(find.text('What is your goal?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onb-goal-LOSE')));
    await tester.pump();
    await _next(tester);
    await _next(tester);
    await tester.ensureVisible(find.byKey(const Key('onb-activity-LIGHT')));
    await tester.tap(find.byKey(const Key('onb-activity-LIGHT')));
    await tester.pump();
    await _next(tester);
    await tester.ensureVisible(find.byKey(const Key('onb-care-NONE')));
    await tester.tap(find.byKey(const Key('onb-care-NONE')));
    await tester.pump();
    await _next(tester);
    await _next(tester);
    await _next(tester);
    expect(find.text('How did we calculate this?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testNutriguide('a profile that already exists opens home', (tester) async {
    final auth = FakeAuthRepository(
      restored: const SignedIn(account: AccountInfo(hasProfile: false)),
    );
    var calls = 0;
    auth.onAccount = () async {
      calls += 1;
      if (calls == 1) {
        throw const NetworkUnavailable();
      }
      return const AccountInfo(hasProfile: true, email: 'a@b.co');
    };
    await pumpNutriguide(tester, auth: auth);

    expect(find.byKey(const Key('today-screen')), findsOneWidget);
    expect(find.text('عرّفنا بنفسك'), findsNothing);
  });
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('onb-continue')));
  await tester.pumpAndSettle();
}
