import 'package:dio/dio.dart';

import '../../../core/api/generated/models/water_day.dart';
import '../../../core/network/app_failure.dart';
import '../../plan/domain/plan_dates.dart';
import '../domain/water.dart';

class WaterApi {
  WaterApi(this._dio);

  final Dio _dio;

  Future<WaterDay> day(DateTime date) {
    return _guard(() async {
      final response = await _dio.get<Object>(
        '/api/v1/water',
        queryParameters: <String, Object?>{'date': isoDate(dateOnly(date))},
      );
      return WaterDay.fromJson(_object(response.data));
    });
  }

  /// Saves the amount the doctor set. `PUT /me/profile` replaces the whole
  /// profile, so the current one is read and sent back unchanged except for
  /// `water_goal_ml`. The read-only latest weight fields are dropped.
  Future<void> setGoal(int goalMl) {
    return _guard(() async {
      final current = await _dio.get<Object>('/api/v1/me/profile');
      final state = _object(current.data);
      final profile = Map<String, Object?>.from(_object(state['profile']))
        ..remove('latest_weight_kg')
        ..remove('latest_weight_on')
        ..['water_goal_ml'] = goalMl;
      await _dio.put<Object>('/api/v1/me/profile', data: profile);
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on WaterException {
      rethrow;
    } on DioException catch (error) {
      final failure = mapDioException(error);
      throw switch (failure) {
        NetworkUnavailable() ||
        Timeout() => const WaterException('NETWORK', network: true),
        ApiProblem(:final code) => WaterException(code),
        UnexpectedResponse() => const WaterException('UNEXPECTED'),
      };
    } on Object {
      throw const WaterException('UNEXPECTED');
    }
  }
}

Map<String, Object?> _object(Object? data) {
  if (data is Map) {
    return Map<String, Object?>.from(data);
  }
  throw const WaterException('UNEXPECTED');
}
