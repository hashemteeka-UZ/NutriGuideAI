import 'package:nutriguide/core/network/app_failure.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/auth_repository.dart';
import 'package:nutriguide/features/auth/domain/session.dart';

final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.restored = const SignedOut()});

  SessionState restored;
  Future<AccountInfo> Function(String email, String password)? onLogin;
  Future<AccountInfo> Function(String email, String password)? onRegister;
  int accountCalls = 0;
  int logoutCalls = 0;
  int profileMarks = 0;
  Future<AccountInfo> Function()? onAccount;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<AccountInfo> register({
    required String email,
    required String password,
  }) {
    lastEmail = email;
    lastPassword = password;
    final handler = onRegister;
    if (handler == null) {
      throw StateError('register was not expected');
    }
    return handler(email, password);
  }

  @override
  Future<AccountInfo> login({required String email, required String password}) {
    lastEmail = email;
    lastPassword = password;
    final handler = onLogin;
    if (handler == null) {
      throw StateError('login was not expected');
    }
    return handler(email, password);
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }

  @override
  Future<void> markHasProfile() async {
    profileMarks += 1;
  }

  @override
  Future<AccountInfo> currentAccount() async {
    accountCalls += 1;
    final handler = onAccount;
    if (handler != null) {
      return handler();
    }
    throw const NetworkUnavailable();
  }

  @override
  Future<SessionState> restore() async => restored;
}
