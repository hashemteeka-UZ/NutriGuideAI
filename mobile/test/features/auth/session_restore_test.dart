import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/clients/account_client.dart';
import 'package:nutriguide/core/api/generated/clients/auth_client.dart';
import 'package:nutriguide/features/auth/data/auth_repository_impl.dart';
import 'package:nutriguide/features/auth/data/token_store.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/auth/presentation/session_controller.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/memory_secure.dart';

void main() {
  test('no refresh token restores signed out', () async {
    final repo = _repo(MemorySecure());

    final session = await repo.restore();

    expect(session, isA<SignedOut>());
  });

  test('cached has_profile restores signed in without network', () async {
    final storage = MemorySecure();
    await SecureTokenStore(storage).save(
      AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        accessExpiry: DateTime.utc(2026, 10, 23, 12),
        hasProfile: true,
      ),
    );
    var calls = 0;
    final repo = _repo(
      storage,
      onFetch: (RequestOptions options) async {
        calls += 1;
        return _json(500, <String, Object?>{'code': 'INTERNAL_ERROR'});
      },
    );

    final session = await repo.restore();

    expect(calls, 0);
    expect(session, isA<SignedIn>());
    expect((session as SignedIn).hasProfile, isTrue);
    expect(session.account?.email, isNull);
  });

  test('offline /me keeps the restored session', () async {
    final auth = FakeAuthRepository(
      restored: const SignedIn(
        account: AccountInfo(hasProfile: true, email: 'a@b.co'),
      ),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    final subscription = container.listen(sessionControllerProvider, (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    await pumpEventQueue();
    await pumpEventQueue();

    final session = container.read(sessionControllerProvider);
    expect(session, isA<SignedIn>());
    expect((session as SignedIn).hasProfile, isTrue);
    expect(session.account?.email, 'a@b.co');
    expect(auth.accountCalls, 1);
  });

  test('register sends the trimmed email without lowercasing it', () async {
    Object? sent;
    final storage = MemorySecure();
    final repo = _repo(
      storage,
      onFetch: (RequestOptions options) async {
        if (options.uri.path.endsWith('/auth/register')) {
          sent = options.data;
          return _json(201, <String, Object?>{
            'access_token': 'access',
            'refresh_token': 'refresh',
            'token_type': 'bearer',
            'expires_in': 900,
          });
        }
        return _json(200, <String, Object?>{
          'user_id': 4,
          'email': 'User@Example.com',
          'created_at': '2026-10-01T09:00:00Z',
          'has_profile': false,
        });
      },
    );

    final account = await repo.register(
      email: '  User@Example.com  ',
      password: '12345678',
    );

    expect(sent, isA<Map<dynamic, dynamic>>());
    expect((sent! as Map)['email'], 'User@Example.com');
    expect(account.email, 'User@Example.com');
    expect(account.hasProfile, isFalse);
    expect(
      SecureTokenStore(storage).current?.refreshToken ??
          (await SecureTokenStore(storage).read())?.refreshToken,
      'refresh',
    );
  });
}

AuthRepositoryImpl _repo(
  MemorySecure storage, {
  Future<ResponseBody> Function(RequestOptions options)? onFetch,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
  dio.httpClientAdapter = _Adapter(
    onFetch ??
        (RequestOptions options) async {
          return _json(500, <String, Object?>{});
        },
  );
  return AuthRepositoryImpl(
    auth: AuthClient(dio),
    account: AccountClient(dio),
    tokens: SecureTokenStore(storage),
  );
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this._onFetch);

  final Future<ResponseBody> Function(RequestOptions options) _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object? body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>['application/json'],
    },
  );
}
