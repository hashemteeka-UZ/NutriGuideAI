import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/clients/auth_client.dart';
import '../../../core/api/generated/models/refresh_request.dart';
import '../../../core/config/app_config.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/network/app_failure.dart';
import '../../../core/network/debug_request_log.dart';
import '../../../core/network/dio_provider.dart';
import '../session_signals.dart';
import 'token_store.dart';

const authRetriedExtraKey = 'ng.auth.retried';

const _refreshLead = Duration(seconds: 60);

bool isPublicApiPath(String path) {
  return path == '/api/v1/health' ||
      path == '/api/v1/reference' ||
      path.startsWith('/api/v1/auth/');
}

/// Queued so a refresh finishes before the next protected send, while
/// in-flight 401s still share one refresh future across the error queue.
final class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStore tokenStore,
    required Dio refreshDio,
    required Dio retryDio,
    required SessionSignals signals,
    required LocaleCode locale,
    DateTime Function()? now,
    AuthClient? refreshClient,
  }) : _tokens = tokenStore,
       _refreshDio = refreshDio,
       // Names differ from the fields so callers keep a public parameter name.
       // ignore: prefer_initializing_formals
       _retryDio = retryDio,
       // ignore: prefer_initializing_formals
       _signals = signals,
       // ignore: prefer_initializing_formals
       _locale = locale,
       _now = now ?? DateTime.now,
       _refreshClient = refreshClient ?? AuthClient(refreshDio);

  final TokenStore _tokens;
  final Dio _refreshDio;
  final Dio _retryDio;
  final SessionSignals _signals;
  final LocaleCode _locale;
  final DateTime Function() _now;
  final AuthClient _refreshClient;
  Future<void>? _refreshing;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      options.headers['Accept-Language'] = _locale.code;
      if (isPublicApiPath(options.uri.path)) {
        options.headers.remove('Authorization');
        handler.next(options);
        return;
      }
      await _tokens.ensureLoaded();
      if (_accessExpiresSoon()) {
        await _refreshShared();
      }
      final access = _tokens.current?.accessToken;
      if (access != null && access.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $access';
      } else {
        options.headers.remove('Authorization');
      }
      handler.next(options);
    } on AppFailure catch (failure) {
      _rejectRequest(handler, options, failure);
    } on Object {
      _rejectRequest(handler, options, const UnexpectedResponse(null));
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      final options = err.requestOptions;
      final failure = mapDioException(err);
      if (failure is ApiProblem && failure.code == 'TOKEN_REUSED') {
        await _signOut();
        _rejectError(handler, options, failure, response: err.response);
        return;
      }
      final retried = options.extra[authRetriedExtraKey] == true;
      final unauthorized =
          failure is ApiProblem && failure.code == 'UNAUTHORIZED';
      if (retried || !unauthorized || isPublicApiPath(options.uri.path)) {
        handler.next(err);
        return;
      }
      if (_hasNewerAccess(options)) {
        await _retry(options, handler);
        return;
      }
      try {
        await _refreshShared();
      } on AppFailure catch (refreshFailure) {
        _rejectError(handler, options, refreshFailure);
        return;
      }
      await _retry(options, handler);
    } on Object {
      if (!handler.isCompleted) {
        handler.next(err);
      }
    }
  }

  bool _accessExpiresSoon() {
    final current = _tokens.current;
    if (current == null || current.refreshToken.isEmpty) {
      return false;
    }
    if (current.accessToken.isEmpty) {
      return true;
    }
    final now = _now().toUtc();
    return !current.accessExpiry.toUtc().isAfter(now.add(_refreshLead));
  }

  bool _hasNewerAccess(RequestOptions options) {
    final current = _tokens.current?.accessToken;
    if (current == null || current.isEmpty) {
      return false;
    }
    return _authorization(options) != 'Bearer $current';
  }

  Future<void> _refreshShared() {
    final existing = _refreshing;
    if (existing != null) {
      return existing;
    }
    final future = _refresh();
    _refreshing = future;
    return future.whenComplete(() {
      if (identical(_refreshing, future)) {
        _refreshing = null;
      }
    });
  }

  Future<void> _refresh() async {
    final refreshToken = _tokens.current?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _signOut();
      throw const ApiProblem(
        status: 401,
        code: 'TOKEN_INVALID',
        title: null,
        detail: null,
        requestId: null,
        retryAfter: null,
      );
    }
    _refreshDio.options.headers['Accept-Language'] = _locale.code;
    try {
      final pair = await _refreshClient.refreshSession(
        body: RefreshRequest(refreshToken: refreshToken),
      );
      final hasProfile = _tokens.current?.hasProfile ?? false;
      await _tokens.save(
        AuthTokens(
          accessToken: pair.accessToken,
          refreshToken: pair.refreshToken,
          accessExpiry: _now().toUtc().add(Duration(seconds: pair.expiresIn)),
          hasProfile: hasProfile,
        ),
      );
    } on DioException catch (error) {
      final failure = mapDioException(error);
      if (_revokesSession(failure)) {
        await _signOut();
      }
      throw failure;
    } on AppFailure {
      rethrow;
    } on Object {
      throw const UnexpectedResponse(null);
    }
  }

  Future<void> _retry(
    RequestOptions options,
    ErrorInterceptorHandler handler,
  ) async {
    final headers = Map<String, dynamic>.of(options.headers);
    final access = _tokens.current?.accessToken;
    if (access != null && access.isNotEmpty) {
      headers['Authorization'] = 'Bearer $access';
    }
    headers['Accept-Language'] = _locale.code;
    final extra = Map<String, dynamic>.of(options.extra)
      ..[authRetriedExtraKey] = true;
    final request = options.copyWith(headers: headers, extra: extra);
    try {
      final response = await _retryDio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (error) {
      _rejectError(
        handler,
        request,
        mapDioException(error),
        response: error.response,
      );
    }
  }

  Future<void> _signOut() async {
    await _tokens.clear();
    _signals.onSessionEnded?.call();
  }

  void _rejectRequest(
    RequestInterceptorHandler handler,
    RequestOptions options,
    AppFailure failure,
  ) {
    if (handler.isCompleted) {
      return;
    }
    handler.reject(_exception(options, failure));
  }

  void _rejectError(
    ErrorInterceptorHandler handler,
    RequestOptions options,
    AppFailure failure, {
    Response<dynamic>? response,
  }) {
    if (handler.isCompleted) {
      return;
    }
    handler.reject(_exception(options, failure, response: response));
  }

  DioException _exception(
    RequestOptions options,
    AppFailure failure, {
    Response<dynamic>? response,
  }) {
    final headers = Map<String, dynamic>.of(options.headers)
      ..remove('Authorization');
    return DioException(
      requestOptions: options.copyWith(headers: headers, data: null),
      response: response,
      type: switch (failure) {
        NetworkUnavailable() => DioExceptionType.connectionError,
        Timeout() => DioExceptionType.receiveTimeout,
        _ => DioExceptionType.badResponse,
      },
      error: failure,
      message: failure.toString(),
    );
  }
}

bool _revokesSession(AppFailure failure) {
  return failure is ApiProblem &&
      (failure.code == 'TOKEN_REUSED' || failure.code == 'TOKEN_INVALID');
}

String? _authorization(RequestOptions options) {
  for (final entry in options.headers.entries) {
    if (entry.key.toLowerCase() == 'authorization') {
      return entry.value?.toString();
    }
  }
  return null;
}

Dio bareDio(AppConfig config) {
  return Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
}

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final appDio = ref.watch(dioProvider);
  final config = ref.watch(appConfigProvider);
  final refreshDio = bareDio(config);
  final retryDio = bareDio(config);
  retryDio.httpClientAdapter = appDio.httpClientAdapter;
  if (kDebugMode) {
    refreshDio.interceptors.add(const DebugRequestLogInterceptor());
  }
  final interceptor = AuthInterceptor(
    tokenStore: ref.watch(tokenStoreProvider),
    refreshDio: refreshDio,
    retryDio: retryDio,
    signals: ref.watch(sessionSignalsProvider),
    locale: ref.watch(localeCodeProvider),
  );
  appDio.interceptors.insert(0, interceptor);
  ref.onDispose(() {
    appDio.interceptors.remove(interceptor);
    refreshDio.close(force: true);
  });
  return interceptor;
});
