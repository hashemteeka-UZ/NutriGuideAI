import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs method, path, status, and duration. Headers and bodies are omitted.
final class DebugRequestLogInterceptor extends Interceptor {
  const DebugRequestLogInterceptor();

  static const _startedAtKey = 'ng_started_us';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now().microsecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _log(RequestOptions options, int? statusCode) {
    final started = options.extra[_startedAtKey];
    final duration = started is int
        ? '${((DateTime.now().microsecondsSinceEpoch - started) / 1000).round()}ms'
        : '-';
    debugPrint(
      '${options.method} ${options.uri.path} ${statusCode ?? '-'} $duration',
    );
  }
}
