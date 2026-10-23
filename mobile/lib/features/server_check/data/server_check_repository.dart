import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/generated/clients/health_client.dart';
import '../../../core/api/generated/models/health_response.dart';
import '../../../core/network/app_failure.dart';
import '../domain/server_status.dart';

abstract interface class ServerCheckRepository {
  Future<ServerStatus> load();
}

final class ApiServerCheckRepository implements ServerCheckRepository {
  ApiServerCheckRepository(this._client);

  final HealthClient _client;

  @override
  Future<ServerStatus> load() async {
    try {
      final health = await _client.health();
      return mapHealthResponse(health);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}

ServerStatus mapHealthResponse(HealthResponse health) {
  return ServerStatus(
    apiVersion: health.apiVersion,
    datasetVersion: health.datasetVersion,
    plannerName: health.defaultPlanner,
  );
}

final serverCheckRepositoryProvider = Provider<ServerCheckRepository>((ref) {
  return ApiServerCheckRepository(ref.watch(healthClientProvider));
});
