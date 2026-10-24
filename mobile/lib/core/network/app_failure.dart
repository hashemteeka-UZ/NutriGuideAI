import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

sealed class AppFailure implements Exception {
  const AppFailure();
}

class FieldIssue {
  const FieldIssue({required this.loc, required this.msg, required this.type});

  final List<Object> loc;
  final String msg;
  final String type;
}

final class ApiProblem extends AppFailure {
  const ApiProblem({
    required this.status,
    required this.code,
    required this.title,
    required this.detail,
    required this.requestId,
    required this.retryAfter,
    this.errors = const <FieldIssue>[],
    this.reasons,
  });

  final int status;
  final String code;
  final String? title;
  final String? detail;
  final String? requestId;
  final int? retryAfter;
  final List<FieldIssue> errors;
  final List<String>? reasons;

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
  final carried = error.error;
  if (carried is AppFailure) {
    return carried;
  }
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
      errors: _parseErrors(body['errors']),
      reasons: _parseReasons(body['reasons']),
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

List<FieldIssue> _parseErrors(Object? raw) {
  if (raw is! List) {
    return const <FieldIssue>[];
  }
  final issues = <FieldIssue>[];
  for (final Object? item in raw) {
    final issue = _parseIssue(item);
    if (issue != null) {
      issues.add(issue);
    }
  }
  return issues;
}

FieldIssue? _parseIssue(Object? item) {
  if (item is! Map) {
    return null;
  }
  try {
    final mapped = _stringKeyMap(item);
    final locRaw = mapped['loc'];
    final msg = mapped['msg'];
    final type = mapped['type'];
    if (locRaw is! List || msg is! String || type is! String) {
      return null;
    }
    final loc = <Object>[];
    for (final Object? part in locRaw) {
      if (part is String) {
        loc.add(part);
      } else if (part is int) {
        loc.add(part);
      } else {
        return null;
      }
    }
    return FieldIssue(loc: loc, msg: msg, type: type);
  } on Object {
    return null;
  }
}

List<String>? _parseReasons(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is! List) {
    return null;
  }
  final reasons = <String>[];
  for (final Object? item in raw) {
    if (item is! String) {
      return null;
    }
    reasons.add(item);
  }
  return reasons;
}

int? _retryAfterSeconds(Headers headers) {
  final header = headers.value('retry-after');
  if (header == null) {
    return null;
  }
  return int.tryParse(header.trim());
}
