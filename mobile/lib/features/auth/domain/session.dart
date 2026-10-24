import 'account_info.dart';

enum SignOutReason { sessionExpired }

sealed class SessionState {
  const SessionState();
}

final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

final class SignedOut extends SessionState {
  const SignedOut({this.reason});

  final SignOutReason? reason;
}

final class SignedIn extends SessionState {
  const SignedIn({this.account});

  final AccountInfo? account;

  bool get hasProfile => account?.hasProfile ?? false;
}
