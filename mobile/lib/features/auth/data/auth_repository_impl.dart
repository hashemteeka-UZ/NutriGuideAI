// Public constructor parameters keep their names; the fields stay private.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/generated/clients/account_client.dart';
import '../../../core/api/generated/clients/auth_client.dart';
import '../../../core/api/generated/models/account.dart';
import '../../../core/api/generated/models/login_request.dart';
import '../../../core/api/generated/models/refresh_request.dart';
import '../../../core/api/generated/models/register_request.dart';
import '../../../core/api/generated/models/token_pair.dart';
import '../../../core/network/app_failure.dart';
import '../domain/account_info.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';
import 'token_store.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthClient auth,
    required AccountClient account,
    required TokenStore tokens,
    DateTime Function()? now,
  }) : _auth = auth,
       _account = account,
       _tokens = tokens,
       _now = now ?? DateTime.now;

  final AuthClient _auth;
  final AccountClient _account;
  final TokenStore _tokens;
  final DateTime Function() _now;

  @override
  Future<AccountInfo> register({
    required String email,
    required String password,
  }) {
    final trimmed = email.trim();
    return _openSession(
      () => _auth.register(
        body: RegisterRequest(email: trimmed, password: password),
      ),
    );
  }

  @override
  Future<AccountInfo> login({required String email, required String password}) {
    final trimmed = email.trim();
    return _openSession(
      () => _auth.login(
        body: LoginRequest(email: trimmed, password: password),
      ),
    );
  }

  @override
  Future<void> logout() async {
    final refresh = _tokens.current?.refreshToken;
    await _tokens.clear();
    if (refresh == null || refresh.isEmpty) {
      return;
    }
    unawaited(_revoke(refresh));
  }

  @override
  Future<void> markHasProfile() {
    return _tokens.updateHasProfile(true);
  }

  @override
  Future<AccountInfo> currentAccount() async {
    try {
      final account = accountInfoFrom(await _account.getMe());
      await _tokens.updateHasProfile(account.hasProfile);
      return account;
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<SessionState> restore() async {
    final tokens = await _tokens.read();
    if (tokens == null) {
      return const SignedOut();
    }
    return SignedIn(account: AccountInfo(hasProfile: tokens.hasProfile));
  }

  Future<AccountInfo> _openSession(Future<TokenPair> Function() request) async {
    final TokenPair pair;
    try {
      pair = await request();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
    await _tokens.save(
      AuthTokens(
        accessToken: pair.accessToken,
        refreshToken: pair.refreshToken,
        accessExpiry: _now().toUtc().add(Duration(seconds: pair.expiresIn)),
        hasProfile: false,
      ),
    );
    try {
      return await currentAccount();
    } on AppFailure catch (failure) {
      if (_revokesSession(failure)) {
        rethrow;
      }
      if (_keepsSession(failure)) {
        return AccountInfo(hasProfile: _tokens.current?.hasProfile ?? false);
      }
      rethrow;
    }
  }

  Future<void> _revoke(String refreshToken) async {
    try {
      await _auth.logout(body: RefreshRequest(refreshToken: refreshToken));
    } on Object {
      // The local session is already gone. Offline logout must succeed.
    }
  }
}

AccountInfo accountInfoFrom(Account account) {
  return AccountInfo(
    userId: account.userId,
    email: account.email,
    createdAt: account.createdAt,
    hasProfile: account.hasProfile,
  );
}

bool _revokesSession(AppFailure failure) {
  return failure is ApiProblem &&
      (failure.code == 'TOKEN_REUSED' || failure.code == 'TOKEN_INVALID');
}

bool _keepsSession(AppFailure failure) {
  return failure is NetworkUnavailable ||
      failure is Timeout ||
      failure is UnexpectedResponse ||
      (failure is ApiProblem && failure.status >= 500);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    auth: ref.watch(authClientProvider),
    account: ref.watch(accountClientProvider),
    tokens: ref.watch(tokenStoreProvider),
  );
});
