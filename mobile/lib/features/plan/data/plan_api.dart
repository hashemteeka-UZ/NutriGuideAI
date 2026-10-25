import 'package:dio/dio.dart';

import '../../../core/api/generated/models/alternative.dart';
import '../../../core/api/generated/models/day_plan_out.dart';
import '../../../core/api/generated/models/day_view.dart';
import '../../../core/api/generated/models/plan_item_out.dart';
import '../../../core/api/generated/models/shopping_list.dart';
import '../../../core/network/app_failure.dart';
import '../../shopping/domain/shopping.dart';
import '../domain/plan.dart';
import '../domain/plan_dates.dart';
import 'plan_mapper.dart';

/// Plan calls send a calendar date. The generated client sends a full
/// timestamp, which this API does not accept for `format: date`.
class PlanApi {
  PlanApi(this._dio);

  final Dio _dio;

  Future<DayPlan> createDay(DateTime date) {
    return _guard(() async {
      final response = await _dio.post<Object>(
        '/api/v1/plans/days',
        data: <String, Object?>{'date': isoDate(dateOnly(date))},
      );
      return dayPlanFromApi(DayPlanOut.fromJson(_object(response.data)));
    });
  }

  Future<List<DayPlan>> listPlans({
    required DateTime from,
    required DateTime to,
  }) {
    return _guard(() async {
      final response = await _dio.get<Object>(
        '/api/v1/plans',
        queryParameters: <String, Object?>{
          'from': isoDate(dateOnly(from)),
          'to': isoDate(dateOnly(to)),
        },
      );
      final data = response.data;
      if (data is! List) {
        throw const PlanRequestException(code: 'UNEXPECTED');
      }
      return <DayPlan>[
        for (final Object? item in data)
          dayPlanFromApi(DayPlanOut.fromJson(_object(item))),
      ];
    });
  }

  Future<DayDetail> fetchDay(DateTime date) {
    return _guard(() async {
      final response = await _dio.get<Object>(
        '/api/v1/days/${isoDate(dateOnly(date))}',
      );
      return dayDetailFromApi(DayView.fromJson(_object(response.data)));
    });
  }

  Future<List<PlanAlternative>> alternatives(int planItemId) {
    return _guard(() async {
      final response = await _dio.get<Object>(
        '/api/v1/plan-items/$planItemId/alternatives',
      );
      final data = response.data;
      if (data is! List) {
        throw const PlanRequestException(code: 'UNEXPECTED');
      }
      return <PlanAlternative>[
        for (final Object? item in data.take(10))
          alternativeFromApi(Alternative.fromJson(_object(item))),
      ];
    });
  }

  Future<PlanItem> swap({required int planItemId, required int mealId}) {
    return _guard(() async {
      final response = await _dio.post<Object>(
        '/api/v1/plan-items/$planItemId/swap',
        data: <String, Object?>{'meal_id': mealId},
      );
      final item = PlanItemOut.fromJson(_object(response.data));
      return planItemFromApi(item, planDate: '', position: 0);
    });
  }

  Future<List<ShoppingRow>> shopping({
    required DateTime from,
    required DateTime to,
  }) {
    return _guard(() async {
      final response = await _dio.get<Object>(
        '/api/v1/shopping-list',
        queryParameters: <String, Object?>{
          'from': isoDate(dateOnly(from)),
          'to': isoDate(dateOnly(to)),
        },
      );
      final list = ShoppingList.fromJson(_object(response.data));
      return <ShoppingRow>[
        for (final item in list.items) shoppingRowFromApi(item),
      ];
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PlanRequestException {
      rethrow;
    } on DioException catch (error) {
      throw _fromFailure(mapDioException(error));
    } on Object {
      throw const PlanRequestException(code: 'UNEXPECTED');
    }
  }
}

PlanRequestException _fromFailure(AppFailure failure) {
  return switch (failure) {
    NetworkUnavailable() ||
    Timeout() => const PlanRequestException(network: true),
    ApiProblem(:final code, :final retryAfter) => PlanRequestException(
      code: code,
      retryAfterSeconds: retryAfter,
    ),
    UnexpectedResponse() => const PlanRequestException(code: 'UNEXPECTED'),
  };
}

Map<String, dynamic> _object(Object? data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw const PlanRequestException(code: 'UNEXPECTED');
}
