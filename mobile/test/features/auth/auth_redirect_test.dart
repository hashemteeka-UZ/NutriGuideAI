import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/app/router.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';

void main() {
  const locations = <String>[
    '/splash',
    '/welcome',
    '/register',
    '/login',
    '/onboarding',
    '/home',
    '/meals',
    '/meals/favourites',
    '/meals/12',
    '/dev/server-check',
    '/elsewhere',
  ];

  final sessions = <String, SessionState>{
    'unknown': const SessionUnknown(),
    'signed out': const SignedOut(),
    'session expired': const SignedOut(reason: SignOutReason.sessionExpired),
    'signed in without profile': const SignedIn(
      account: AccountInfo(hasProfile: false),
    ),
    'signed in with profile': const SignedIn(
      account: AccountInfo(hasProfile: true, email: 'a@b.co'),
    ),
    'signed in without account': const SignedIn(),
  };

  for (final allowServerCheck in const <bool>[false, true]) {
    for (final session in sessions.entries) {
      for (final location in locations) {
        test('${session.key} x $location (server check $allowServerCheck)', () {
          expect(
            authRedirect(
              session: session.value,
              location: location,
              allowServerCheck: allowServerCheck,
            ),
            _expected(session.value, location, allowServerCheck),
          );
        });
      }
    }
  }
}

String? _expected(
  SessionState session,
  String location,
  bool allowServerCheck,
) {
  if (allowServerCheck && location == '/dev/server-check') {
    return null;
  }
  return switch (session) {
    SessionUnknown() => location == '/splash' ? null : '/splash',
    SignedOut(:final reason) => _signedOut(location, reason),
    SignedIn(:final hasProfile) => _signedIn(location, hasProfile),
  };
}

String? _signedIn(String location, bool hasProfile) {
  if (!hasProfile) {
    return location == '/onboarding' ? null : '/onboarding';
  }
  if (location == '/home' ||
      location == '/meals' ||
      location.startsWith('/meals/')) {
    return null;
  }
  return '/home';
}

String? _signedOut(String location, SignOutReason? reason) {
  const allowed = <String>{'/welcome', '/register', '/login'};
  final expired = reason == SignOutReason.sessionExpired;
  if (allowed.contains(location)) {
    if (expired && location != '/login') {
      return '/login';
    }
    return null;
  }
  return expired ? '/login' : '/welcome';
}
