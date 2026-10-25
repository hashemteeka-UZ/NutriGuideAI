import 'package:dio/dio.dart';

import '../api/generated/models/sync_changes.dart';
import '../api/manual/sync_models.dart';
import '../network/app_failure.dart';

/// Why a sync request did not return a body.
enum SyncFailureKind {
  /// No connection, a timeout, a 5xx, or 429. Try again later with the same
  /// operations.
  transient,

  /// The server refused the request itself (a 4xx problem with [code]).
  refused,
}

final class SyncFailure implements Exception {
  const SyncFailure(this.kind, {this.code});

  final SyncFailureKind kind;
  final String? code;

  @override
  String toString() => 'SyncFailure($kind, $code)';
}

abstract interface class SyncApi {
  Future<SyncBatchResult> upload(List<Map<String, Object?>> operations);

  Future<SyncChanges> changes(DateTime since);
}

final class DioSyncApi implements SyncApi {
  DioSyncApi(this._dio);

  final Dio _dio;

  @override
  Future<SyncBatchResult> upload(List<Map<String, Object?>> operations) {
    return _guard(() async {
      final response = await _dio.post<Object>(
        '/api/v1/sync/batch',
        data: <String, Object?>{'operations': operations},
      );
      return SyncBatchResult.fromJson(_object(response.data));
    });
  }

  @override
  Future<SyncChanges> changes(DateTime since) {
    return _guard(() async {
      final response = await _dio.get<Object>(
        '/api/v1/sync/changes',
        queryParameters: <String, Object?>{'since': wireInstant(since)},
      );
      return SyncChanges.fromJson(_object(response.data));
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw syncFailureFrom(mapDioException(error));
    } on SyncFailure {
      rethrow;
    } on Object {
      throw const SyncFailure(SyncFailureKind.refused, code: 'UNEXPECTED');
    }
  }
}

SyncFailure syncFailureFrom(AppFailure failure) {
  return switch (failure) {
    NetworkUnavailable() ||
    Timeout() => const SyncFailure(SyncFailureKind.transient),
    ApiProblem(:final status, :final code) =>
      status >= 500 || status == 429
          ? SyncFailure(SyncFailureKind.transient, code: code)
          : SyncFailure(SyncFailureKind.refused, code: code),
    UnexpectedResponse(:final status) =>
      status == null || status >= 500
          ? const SyncFailure(SyncFailureKind.transient)
          : const SyncFailure(SyncFailureKind.refused, code: 'UNEXPECTED'),
  };
}

Map<String, Object?> _object(Object? data) {
  if (data is Map) {
    return Map<String, Object?>.from(data);
  }
  throw const SyncFailure(SyncFailureKind.refused, code: 'UNEXPECTED');
}
