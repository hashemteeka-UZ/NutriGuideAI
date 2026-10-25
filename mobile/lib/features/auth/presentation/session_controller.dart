import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository_impl.dart';
import '../domain/account_info.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';
import '../session_signals.dart';

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    final signals = ref.read(sessionSignalsProvider);
    void onEnded() {
      _emit(const SignedOut(reason: SignOutReason.sessionExpired));
    }

    signals.onSessionEnded = onEnded;
    ref.onDispose(() {
      if (identical(signals.onSessionEnded, onEnded)) {
        signals.onSessionEnded = null;
      }
    });
    unawaited(_restore());
    return const SessionUnknown();
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final account = await _repository.register(
      email: email,
      password: password,
    );
    _emit(SignedIn(account: account));
  }

  Future<void> login({required String email, required String password}) async {
    final account = await _repository.login(email: email, password: password);
    _emit(SignedIn(account: account));
  }

  Future<void> logout() async {
    await _repository.logout();
    _emit(const SignedOut());
  }

  void adopt(AccountInfo account) {
    if (state is! SignedIn) {
      return;
    }
    _emit(SignedIn(account: account));
  }

  Future<void> completeOnboarding() async {
    await _repository.markHasProfile();
    final current = state;
    if (current is! SignedIn) {
      return;
    }
    final account = current.account;
    _emit(
      SignedIn(
        account: AccountInfo(
          hasProfile: true,
          userId: account?.userId,
          email: account?.email,
          createdAt: account?.createdAt,
        ),
      ),
    );
  }

  void consumeExpiredReason() {
    final current = state;
    if (current is SignedOut && current.reason != null) {
      _emit(const SignedOut());
    }
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> _restore() async {
    final session = await _repository.restore();
    if (!ref.mounted) {
      return;
    }
    _emit(session);
    if (session is SignedIn) {
      unawaited(_loadAccount());
    }
  }

  /// Routing already used the cached session; this only refreshes it, so a
  /// slow or unreachable server must not hold anything up.
  Future<void> _loadAccount() async {
    try {
      final account = await _repository.currentAccount().timeout(
        const Duration(seconds: 3),
      );
      if (!ref.mounted || state is! SignedIn) {
        return;
      }
      _emit(SignedIn(account: account));
    } on Object {
      // A revoked token already moved the session to SignedOut.
      // Network and server failures keep the cached session.
    }
  }

  void _emit(SessionState value) {
    if (!ref.mounted) {
      return;
    }
    state = value;
  }
}
