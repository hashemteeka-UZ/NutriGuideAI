import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/locale/locale_controller.dart';
import 'package:nutriguide/core/network/app_failure.dart';
import 'package:nutriguide/features/auth/data/auth_interceptor.dart';
import 'package:nutriguide/features/auth/data/token_store.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/auth/session_signals.dart';

import '../../support/memory_secure.dart';

void main() {
  final now = DateTime.utc(2026, 10, 23, 12);

  test(
    'public paths have no Authorization header and protected paths do',
    () async {
      final harness = await _harness(
        now: now,
        onFetch: (RequestOptions options) async =>
            _json(200, <String, Object?>{'ok': true}),
      );
      await harness.store.save(_tokens(now.add(const Duration(minutes: 10))));

      await harness.app.get<dynamic>('/api/v1/health');
      await harness.app.get<dynamic>('/api/v1/reference');
      await harness.app.post<dynamic>(
        '/api/v1/auth/login',
        data: <String, Object?>{'email': 'a@b.co', 'password': 'secret'},
        options: Options(
          headers: <String, Object?>{'Authorization': 'Bearer planted'},
        ),
      );
      await harness.app.get<dynamic>('/api/v1/me');

      expect(_header(harness.calls[0], 'authorization'), isNull);
      expect(_header(harness.calls[1], 'authorization'), isNull);
      expect(_header(harness.calls[2], 'authorization'), isNull);
      expect(_header(harness.calls[3], 'authorization'), 'Bearer access-1');
      for (final call in harness.calls) {
        expect(_header(call, 'accept-language'), 'ar');
      }
    },
  );

  test('401 UNAUTHORIZED refreshes once, persists, then retries', () async {
    var persistedBeforeRetry = false;
    late final _Harness harness;
    harness = await _harness(
      now: now,
      onFetch: (RequestOptions options) async {
        if (_isRefresh(options)) {
          return _json(200, _pair('access-2', 'refresh-2'));
        }
        if (_header(options, 'authorization') == 'Bearer access-2') {
          persistedBeforeRetry =
              harness.storage.values[SecureTokenStore.refreshKey] ==
              'refresh-2';
          expect(options.extra[authRetriedExtraKey], isTrue);
          return _json(200, <String, Object?>{'ok': true});
        }
        return _problem(401, 'UNAUTHORIZED');
      },
    );
    await harness.store.save(_tokens(now.add(const Duration(minutes: 10))));

    final response = await harness.app.get<Map<String, Object?>>('/api/v1/me');

    expect(response.statusCode, 200);
    expect(harness.refreshCount, 1);
    expect(persistedBeforeRetry, isTrue);
    expect(harness.store.current?.accessToken, 'access-2');
    expect(harness.calls.where(_isMe).length, 2);
  });

  test('three concurrent 401s share one refresh and all succeed', () async {
    final harness = await _harness(
      now: now,
      onFetch: (RequestOptions options) async {
        if (_isRefresh(options)) {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return _json(200, _pair('access-2', 'refresh-2'));
        }
        if (_header(options, 'authorization') == 'Bearer access-2') {
          return _json(200, <String, Object?>{'ok': true});
        }
        return _problem(401, 'UNAUTHORIZED');
      },
    );
    await harness.store.save(_tokens(now.add(const Duration(minutes: 10))));

    final results = await Future.wait(<Future<Response<dynamic>>>[
      harness.app.get<dynamic>('/api/v1/me'),
      harness.app.get<dynamic>('/api/v1/me'),
      harness.app.get<dynamic>('/api/v1/me'),
    ]);

    expect(
      results.map((Response<dynamic> response) => response.statusCode),
      <int>[200, 200, 200],
    );
    expect(harness.refreshCount, 1);
  });

  test(
    'access expiring within 60 seconds refreshes before the request',
    () async {
      final harness = await _harness(
        now: now,
        onFetch: (RequestOptions options) async {
          if (_isRefresh(options)) {
            return _json(200, _pair('access-2', 'refresh-2'));
          }
          expect(_header(options, 'authorization'), 'Bearer access-2');
          return _json(200, <String, Object?>{'ok': true});
        },
      );
      await harness.store.save(_tokens(now.add(const Duration(seconds: 30))));

      await harness.app.get<dynamic>('/api/v1/me');

      expect(harness.refreshCount, 1);
      expect(_isRefresh(harness.calls.first), isTrue);
      expect(harness.calls.where(_isMe).length, 1);
    },
  );

  test('refresh TOKEN_REUSED clears the store and signs out', () async {
    await _expectRevoked(now, 'TOKEN_REUSED');
  });

  test('refresh TOKEN_INVALID clears the store and signs out', () async {
    await _expectRevoked(now, 'TOKEN_INVALID');
  });

  test(
    'TOKEN_REUSED on a protected request signs out without refresh',
    () async {
      final harness = await _harness(
        now: now,
        onFetch: (RequestOptions options) async =>
            _problem(401, 'TOKEN_REUSED'),
      );
      await harness.store.save(_tokens(now.add(const Duration(minutes: 10))));

      await _expectFailure(
        harness.app.get<dynamic>('/api/v1/me'),
        'TOKEN_REUSED',
      );

      expect(harness.refreshCount, 0);
      expect(harness.store.current, isNull);
      expect(harness.storage.values, isEmpty);
      expect(harness.session, isA<SignedOut>());
      expect(
        (harness.session as SignedOut).reason,
        SignOutReason.sessionExpired,
      );
    },
  );

  test('a network error during refresh keeps tokens and the session', () async {
    final harness = await _harness(
      now: now,
      onFetch: (RequestOptions options) async {
        if (_isRefresh(options)) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: const SocketException('offline'),
          );
        }
        return _problem(401, 'UNAUTHORIZED');
      },
    );
    await harness.store.save(_tokens(now.add(const Duration(minutes: 10))));

    final failure = await _failureOf(harness.app.get<dynamic>('/api/v1/me'));

    expect(failure, isA<NetworkUnavailable>());
    expect(harness.store.current?.refreshToken, 'refresh-1');
    expect(harness.session, isA<SignedIn>());
    expect(harness.calls.where(_isMe).length, 1);
  });

  test('a retried 401 is not refreshed a second time', () async {
    final harness = await _harness(
      now: now,
      onFetch: (RequestOptions options) async {
        if (_isRefresh(options)) {
          return _json(200, _pair('access-2', 'refresh-2'));
        }
        return _problem(401, 'UNAUTHORIZED');
      },
    );
    await harness.store.save(_tokens(now.add(const Duration(minutes: 10))));

    await _expectFailure(
      harness.app.get<dynamic>('/api/v1/me'),
      'UNAUTHORIZED',
    );

    expect(harness.refreshCount, 1);
    expect(harness.calls.where(_isMe).length, 2);
    expect(harness.session, isA<SignedIn>());
  });
}

Future<void> _expectRevoked(DateTime now, String code) async {
  final harness = await _harness(
    now: now,
    onFetch: (RequestOptions options) async {
      if (_isRefresh(options)) {
        return _problem(401, code);
      }
      return _problem(401, 'UNAUTHORIZED');
    },
  );
  await harness.store.save(_tokens(now.add(const Duration(minutes: 10))));

  await _expectFailure(harness.app.get<dynamic>('/api/v1/me'), code);

  expect(harness.refreshCount, 1);
  expect(harness.calls.where(_isMe).length, 1);
  expect(harness.store.current, isNull);
  expect(harness.storage.values, isEmpty);
  expect(
    harness.session,
    isA<SignedOut>().having(
      (SignedOut state) => state.reason,
      'reason',
      SignOutReason.sessionExpired,
    ),
  );
}

Future<AppFailure> _failureOf(Future<Response<dynamic>> request) async {
  try {
    await request;
    fail('expected the request to fail');
  } on DioException catch (error) {
    return mapDioException(error);
  }
}

Future<void> _expectFailure(
  Future<Response<dynamic>> request,
  String code,
) async {
  final failure = await _failureOf(request);
  expect(
    failure,
    isA<ApiProblem>().having((ApiProblem p) => p.code, 'code', code),
  );
}

class _Harness {
  _Harness({
    required this.app,
    required this.store,
    required this.storage,
    required this.calls,
  });

  final Dio app;
  final SecureTokenStore store;
  final MemorySecure storage;
  final List<RequestOptions> calls;
  SessionState session = const SignedIn(
    account: AccountInfo(hasProfile: false),
  );

  int get refreshCount => calls.where(_isRefresh).length;
}

Future<_Harness> _harness({
  required DateTime now,
  required Future<ResponseBody> Function(RequestOptions options) onFetch,
}) async {
  final calls = <RequestOptions>[];
  final adapter = _Adapter((RequestOptions options) async {
    calls.add(options);
    return onFetch(options);
  });
  final app = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
  final refresh = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  final retry = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
  app.httpClientAdapter = adapter;
  refresh.httpClientAdapter = adapter;
  retry.httpClientAdapter = adapter;
  final storage = MemorySecure();
  final store = SecureTokenStore(storage);
  final signals = SessionSignals();
  final harness = _Harness(
    app: app,
    store: store,
    storage: storage,
    calls: calls,
  );
  signals.onSessionEnded = () {
    harness.session = const SignedOut(reason: SignOutReason.sessionExpired);
  };
  app.interceptors.add(
    AuthInterceptor(
      tokenStore: store,
      refreshDio: refresh,
      retryDio: retry,
      signals: signals,
      locale: LocaleCode('ar'),
      now: () => now,
    ),
  );
  return harness;
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

AuthTokens _tokens(DateTime expiry) {
  return AuthTokens(
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    accessExpiry: expiry,
    hasProfile: true,
  );
}

Map<String, Object?> _pair(String access, String refresh) {
  return <String, Object?>{
    'access_token': access,
    'refresh_token': refresh,
    'token_type': 'bearer',
    'expires_in': 900,
  };
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

ResponseBody _problem(int status, String code) {
  return _json(status, <String, Object?>{
    'type': 'about:blank',
    'title': code,
    'status': status,
    'code': code,
  });
}

bool _isRefresh(RequestOptions options) =>
    options.uri.path == '/api/v1/auth/refresh';

bool _isMe(RequestOptions options) => options.uri.path == '/api/v1/me';

String? _header(RequestOptions options, String name) {
  for (final entry in options.headers.entries) {
    if (entry.key.toLowerCase() == name) {
      return entry.value?.toString();
    }
  }
  return null;
}
