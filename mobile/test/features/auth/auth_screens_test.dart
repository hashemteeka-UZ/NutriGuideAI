import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/network/app_failure.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/auth/presentation/welcome_screen.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/pump_app.dart';

void main() {
  testWidgets('register shows Arabic validation messages', (tester) async {
    await pumpNutriguide(tester, auth: FakeAuthRepository());

    await _openRegister(tester);
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();

    expect(find.text('أدخل البريد الإلكتروني.'), findsOneWidget);
    expect(find.text('٨ أحرف على الأقل.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('auth-email')), 'not-an-email');
    await tester.enterText(find.byKey(const Key('auth-password')), 'short');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();

    expect(find.text('البريد الإلكتروني غير صالح.'), findsOneWidget);
    expect(find.text('٨ أحرف على الأقل.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('auth-password')), 'x' * 129);
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();

    expect(find.text('١٢٨ حرفًا كحد أقصى.'), findsOneWidget);
  });

  testWidgets('a server field error is shown under that field', (tester) async {
    final auth = FakeAuthRepository();
    auth.onRegister = (String email, String password) async {
      throw const ApiProblem(
        status: 422,
        code: 'VALIDATION_ERROR',
        title: null,
        detail: null,
        requestId: null,
        retryAfter: null,
        errors: <FieldIssue>[
          FieldIssue(
            loc: <Object>['body', 'email'],
            msg: 'bad',
            type: 'value_error',
          ),
        ],
      );
    };
    await pumpNutriguide(tester, auth: auth);
    await _openRegister(tester);
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'ada@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), '12345678');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();

    expect(find.text('البريد الإلكتروني غير صالح.'), findsOneWidget);
  });

  testWidgets('rate limit disables the button for the countdown', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    auth.onLogin = (String email, String password) async {
      throw const ApiProblem(
        status: 429,
        code: 'RATE_LIMITED',
        title: null,
        detail: null,
        requestId: null,
        retryAfter: 2,
      );
    };
    await pumpNutriguide(tester, auth: auth);
    await _openLogin(tester);
    await _submitLogin(tester, 'ada@example.com', '12345678');

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('auth-submit')))
          .onPressed,
      isNull,
    );
    expect(find.text('محاولات كثيرة. حاول بعد ثانيتين.'), findsWidgets);

    await tester.pump(const Duration(seconds: 2));

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('auth-submit')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('login routes to onboarding when the account has no profile', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    auth.onLogin = (String email, String password) async {
      return AccountInfo(hasProfile: false, email: email, userId: 1);
    };
    await pumpNutriguide(tester, auth: auth);
    await _openLogin(tester);
    await _submitLogin(tester, 'new@example.com', '12345678');
    await tester.pumpAndSettle();

    expect(find.text('سنجهز خطتك هنا قريبًا'), findsOneWidget);
  });

  testWidgets('login routes to home when the account has a profile', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    auth.onLogin = (String email, String password) async {
      return AccountInfo(hasProfile: true, email: email, userId: 2);
    };
    await pumpNutriguide(tester, auth: auth);
    await _openLogin(tester);
    await _submitLogin(tester, 'home@example.com', '12345678');
    await tester.pumpAndSettle();

    expect(find.text('أهلًا'), findsOneWidget);
    expect(find.text('home@example.com'), findsOneWidget);
  });

  testWidgets('invalid credentials clears the password only', (tester) async {
    final auth = FakeAuthRepository();
    auth.onLogin = (String email, String password) async {
      throw const ApiProblem(
        status: 401,
        code: 'INVALID_CREDENTIALS',
        title: null,
        detail: null,
        requestId: null,
        retryAfter: null,
      );
    };
    await pumpNutriguide(tester, auth: auth);
    await _openLogin(tester);
    await _submitLogin(tester, 'ada@example.com', 'wrong-password');

    expect(find.text('البريد أو كلمة المرور غير صحيحة.'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('auth-password')))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('auth-email')))
          .controller!
          .text,
      'ada@example.com',
    );
  });

  testWidgets('register shows the already-registered message', (tester) async {
    final auth = FakeAuthRepository();
    auth.onRegister = (String email, String password) async {
      throw const ApiProblem(
        status: 409,
        code: 'EMAIL_TAKEN',
        title: null,
        detail: null,
        requestId: null,
        retryAfter: null,
      );
    };
    await pumpNutriguide(tester, auth: auth);
    await _openRegister(tester);
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'ada@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), '12345678');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();

    expect(
      find.text('هذا البريد مسجل مسبقًا. سجّل الدخول بدلًا من ذلك.'),
      findsOneWidget,
    );
  });

  testWidgets('the submit button is disabled while the request is running', (
    tester,
  ) async {
    final gate = Completer<AccountInfo>();
    addTearDown(() {
      if (!gate.isCompleted) {
        gate.complete(const AccountInfo(hasProfile: false, email: 'a@b.co'));
      }
    });
    final auth = FakeAuthRepository();
    auth.onLogin = (String email, String password) => gate.future;
    await pumpNutriguide(tester, auth: auth);
    await _openLogin(tester);
    await _submitLogin(tester, 'ada@example.com', '12345678');

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('auth-submit')))
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<TextFormField>(find.byKey(const Key('auth-email'))).enabled,
      isFalse,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('welcome and register fit at text scale 1.3', (tester) async {
    await pumpNutriguide(
      tester,
      auth: FakeAuthRepository(),
      logicalSize: const Size(360, 740),
      textScale: 1.3,
    );

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _openRegister(tester);

    expect(find.text('أنشئ حسابك'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the welcome language pill switches direction', (tester) async {
    await pumpNutriguide(tester, auth: FakeAuthRepository());

    expect(find.text('خطة تُبنى لك أنت'), findsOneWidget);
    expect(_direction(tester), TextDirection.rtl);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('A plan built for you'), findsOneWidget);
    expect(_direction(tester), TextDirection.ltr);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(find.text('خطة تُبنى لك أنت'), findsOneWidget);
    expect(_direction(tester), TextDirection.rtl);
  });

  testWidgets('an expired session opens login with a banner', (tester) async {
    await pumpNutriguide(
      tester,
      auth: FakeAuthRepository(
        restored: const SignedOut(reason: SignOutReason.sessionExpired),
      ),
    );

    expect(find.byKey(const Key('session-expired-banner')), findsOneWidget);
    expect(find.text('انتهت الجلسة. سجّل الدخول من جديد.'), findsOneWidget);
  });
}

Future<void> _openRegister(WidgetTester tester) async {
  await tester.ensureVisible(find.text('ابدأ رحلتك'));
  await tester.tap(find.text('ابدأ رحلتك'));
  await tester.pumpAndSettle();
}

Future<void> _openLogin(WidgetTester tester) async {
  await tester.ensureVisible(find.text('لدي حساب'));
  await tester.tap(find.text('لدي حساب'));
  await tester.pumpAndSettle();
}

Future<void> _submitLogin(
  WidgetTester tester,
  String email,
  String password,
) async {
  await tester.enterText(find.byKey(const Key('auth-email')), email);
  await tester.enterText(find.byKey(const Key('auth-password')), password);
  await tester.tap(find.byKey(const Key('auth-submit')));
  await tester.pump();
}

TextDirection _direction(WidgetTester tester) {
  return Directionality.of(tester.element(find.byType(WelcomeScreen)));
}
