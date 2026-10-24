import 'account_info.dart';
import 'session.dart';

abstract interface class AuthRepository {
  Future<AccountInfo> register({
    required String email,
    required String password,
  });

  Future<AccountInfo> login({required String email, required String password});

  Future<void> logout();

  Future<AccountInfo> currentAccount();

  Future<void> markHasProfile();

  Future<SessionState> restore();
}
