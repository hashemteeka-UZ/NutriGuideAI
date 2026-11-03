import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The hosted server sleeps when idle and needs about a minute to answer
/// its first request again (63 s measured on 3 Nov 2026). Sign-in and health
/// calls are usually that first request, so they wait this long.
const Duration wakeReceiveTimeout = Duration(seconds: 90);

/// A wake call still waiting after this long shows the waking banner.
const Duration wakeSlowAfter = Duration(seconds: 4);

const String _retriedKey = 'server_wake_retried';

/// Calls that may be the first one to reach a sleeping server.
bool isWakePath(String path) {
  return path.endsWith('/api/v1/health') || path.contains('/api/v1/auth/');
}

/// Calls that are safe to send twice. Register would fail the second time
/// with EMAIL_TAKEN, and refresh would spend a rotated token, so neither is
/// retried.
bool retriesOnWakeTimeout(String path) {
  return path.endsWith('/api/v1/health') || path.endsWith('/api/v1/auth/login');
}

enum ServerWake { unknown, waking, awake }

class ServerWakeController extends Notifier<ServerWake> {
  @override
  ServerWake build() => ServerWake.unknown;

  void slow() {
    if (state != ServerWake.awake) {
      state = ServerWake.waking;
    }
  }

  void answered() => state = ServerWake.awake;

  void failed() {
    if (state == ServerWake.waking) {
      state = ServerWake.unknown;
    }
  }
}

final serverWakeProvider = NotifierProvider<ServerWakeController, ServerWake>(
  ServerWakeController.new,
);

/// Gives wake calls the long timeout, retries the safe ones once on a
/// timeout, and reports slow, answered, and failed calls.
class ServerWakeInterceptor extends Interceptor {
  ServerWakeInterceptor({
    required this.onSlow,
    required this.onAnswered,
    required this.onFailed,
    this.slowAfter = wakeSlowAfter,
  });

  final void Function() onSlow;
  final void Function() onAnswered;
  final void Function() onFailed;
  final Duration slowAfter;

  /// The Dio this interceptor belongs to, used for the one retry.
  Dio? dio;

  final Map<RequestOptions, Timer> _timers = <RequestOptions, Timer>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (isWakePath(options.path)) {
      final current = options.receiveTimeout;
      if (current == null || current < wakeReceiveTimeout) {
        options.receiveTimeout = wakeReceiveTimeout;
      }
      _timers[options] = Timer(slowAfter, onSlow);
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (_stop(response.requestOptions)) {
      onAnswered();
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (!_stop(options)) {
      handler.next(err);
      return;
    }
    if (err.response != null) {
      onAnswered();
      handler.next(err);
      return;
    }
    final owner = dio;
    if (_isTimeout(err) &&
        owner != null &&
        retriesOnWakeTimeout(options.path) &&
        options.extra[_retriedKey] != true) {
      final extra = Map<String, dynamic>.of(options.extra)
        ..[_retriedKey] = true;
      try {
        handler.resolve(
          await owner.fetch<dynamic>(options.copyWith(extra: extra)),
        );
      } on DioException catch (error) {
        handler.next(error);
      }
      return;
    }
    onFailed();
    handler.next(err);
  }

  bool _stop(RequestOptions options) {
    final timer = _timers.remove(options);
    timer?.cancel();
    return timer != null;
  }
}

bool _isTimeout(DioException err) {
  return err.type == DioExceptionType.connectionTimeout ||
      err.type == DioExceptionType.receiveTimeout ||
      err.type == DioExceptionType.sendTimeout;
}
