import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

sealed class AppFailure implements Exception {
  const AppFailure();
}

final class ApiProblem extends AppFailure {
  const ApiProblem({
    required this.status,
    required this.code,
    required this.title,
    required this.detail,
    required this.requestId,
    required this.retryAfter,
  });

  final int status;
  final String code;
  final String? title;
  final String? detail;
  final String? requestId;
  final int? retryAfter;

  @override
  String toString() => 'ApiProblem($status, $code)';
}

final class NetworkUnavailable extends AppFailure {
  const NetworkUnavailable();

  @override
  String toString() => 'NetworkUnavailable';
}

final class Timeout extends AppFailure {
  const Timeout();

  @override
  String toString() => 'Timeout';
}

final class UnexpectedResponse extends AppFailure {
  const UnexpectedResponse(this.status);

  final int? status;

  @override
  String toString() => 'UnexpectedResponse($status)';
}

AppFailure mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const Timeout();
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return const NetworkUnavailable();
    case DioExceptionType.badResponse:
      return mapResponse(error.response);
    case DioExceptionType.cancel:
      return UnexpectedResponse(error.response?.statusCode);
    case DioExceptionType.unknown:
      if (error.error is SocketException) {
        return const NetworkUnavailable();
      }
      return UnexpectedResponse(error.response?.statusCode);
  }
}

AppFailure mapResponse(Response<dynamic>? response) {
  if (response == null) {
    return const UnexpectedResponse(null);
  }
  final statusCode = response.statusCode;
  final body = _jsonMap(response.data);
  final code = body?['code'];
  if (body != null && code is String) {
    return ApiProblem(
      status: _intValue(body['status']) ?? statusCode ?? 0,
      code: code,
      title: _stringValue(body['title']),
      detail: _stringValue(body['detail']),
      requestId: _stringValue(body['request_id']),
      retryAfter: _retryAfterSeconds(response.headers),
    );
  }
  return UnexpectedResponse(statusCode);
}

Map<String, Object?>? _jsonMap(Object? data) {
  if (data is Map) {
    return _stringKeyMap(data);
  }
  if (data is String && data.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return _stringKeyMap(decoded);
      }
    } on FormatException {
      return null;
    }
  }
  return null;
}

Map<String, Object?> _stringKeyMap(Map<dynamic, dynamic> data) {
  final mapped = <String, Object?>{};
  data.forEach((dynamic key, dynamic value) {
    mapped['$key'] = value as Object?;
  });
  return mapped;
}

String? _stringValue(Object? value) => value is String ? value : null;

int? _intValue(Object? value) => value is int ? value : null;

int? _retryAfterSeconds(Headers headers) {
  final header = headers.value('retry-after');
  if (header == null) {
    return null;
  }
  return int.tryParse(header.trim());
}
