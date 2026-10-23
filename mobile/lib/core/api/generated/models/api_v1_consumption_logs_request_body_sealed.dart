// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'food_log.dart';
import 'meal_log.dart';
import 'meal_slot.dart';
import 'plan_item_log.dart';


part 'api_v1_consumption_logs_request_body_sealed.g.dart';

@JsonSerializable(createFactory: false)
sealed class ApiV1ConsumptionLogsRequestBodySealed {
  const ApiV1ConsumptionLogsRequestBodySealed();
  
  factory ApiV1ConsumptionLogsRequestBodySealed.fromJson(Map<String, dynamic> json) =>
      ApiV1ConsumptionLogsRequestBodySealedDeserializer.tryDeserialize(json);
  
  Map<String, dynamic> toJson();
}

extension ApiV1ConsumptionLogsRequestBodySealedDeserializer on ApiV1ConsumptionLogsRequestBodySealed {
  static ApiV1ConsumptionLogsRequestBodySealed tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'kind',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      ApiV1ConsumptionLogsRequestBodySealedFoodLog: 'FOOD',
      ApiV1ConsumptionLogsRequestBodySealedMealLog: 'MEAL',
      ApiV1ConsumptionLogsRequestBodySealedPlanItemLog: 'PLAN_ITEM',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[ApiV1ConsumptionLogsRequestBodySealedFoodLog] => ApiV1ConsumptionLogsRequestBodySealedFoodLog.fromJson(json),
      _ when value == effective[ApiV1ConsumptionLogsRequestBodySealedMealLog] => ApiV1ConsumptionLogsRequestBodySealedMealLog.fromJson(json),
      _ when value == effective[ApiV1ConsumptionLogsRequestBodySealedPlanItemLog] => ApiV1ConsumptionLogsRequestBodySealedPlanItemLog.fromJson(json),
      _ => throw FormatException('Unknown discriminator value "${json[key]}" for ApiV1ConsumptionLogsRequestBodySealed'),
    };
  }
}

@JsonSerializable()
class ApiV1ConsumptionLogsRequestBodySealedFoodLog extends ApiV1ConsumptionLogsRequestBodySealed implements FoodLog {
  @override
  final String clientUuid;
  @override
  final DateTime consumedAt;
  @override
  final int foodId;
  @override
  final num gramsConsumed;
  @override
  final String kind;
  @override
  final MealSlot? slot;

  const ApiV1ConsumptionLogsRequestBodySealedFoodLog({
    required this.clientUuid,
    required this.consumedAt,
    required this.foodId,
    required this.gramsConsumed,
    required this.kind,
    required this.slot,
  });
  
  factory ApiV1ConsumptionLogsRequestBodySealedFoodLog.fromJson(Map<String, dynamic> json) =>
      _$ApiV1ConsumptionLogsRequestBodySealedFoodLogFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$ApiV1ConsumptionLogsRequestBodySealedFoodLogToJson(this);
}
@JsonSerializable()
class ApiV1ConsumptionLogsRequestBodySealedMealLog extends ApiV1ConsumptionLogsRequestBodySealed implements MealLog {
  @override
  final String clientUuid;
  @override
  final DateTime consumedAt;
  @override
  final String kind;
  @override
  final int mealId;
  @override
  final num servingsConsumed;
  @override
  final MealSlot? slot;

  const ApiV1ConsumptionLogsRequestBodySealedMealLog({
    required this.clientUuid,
    required this.consumedAt,
    required this.kind,
    required this.mealId,
    required this.servingsConsumed,
    required this.slot,
  });
  
  factory ApiV1ConsumptionLogsRequestBodySealedMealLog.fromJson(Map<String, dynamic> json) =>
      _$ApiV1ConsumptionLogsRequestBodySealedMealLogFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$ApiV1ConsumptionLogsRequestBodySealedMealLogToJson(this);
}
@JsonSerializable()
class ApiV1ConsumptionLogsRequestBodySealedPlanItemLog extends ApiV1ConsumptionLogsRequestBodySealed implements PlanItemLog {
  @override
  final String clientUuid;
  @override
  final DateTime consumedAt;
  @override
  final String kind;
  @override
  final int planItemId;
  @override
  final num servingsConsumed;

  const ApiV1ConsumptionLogsRequestBodySealedPlanItemLog({
    required this.clientUuid,
    required this.consumedAt,
    required this.kind,
    required this.planItemId,
    required this.servingsConsumed,
  });
  
  factory ApiV1ConsumptionLogsRequestBodySealedPlanItemLog.fromJson(Map<String, dynamic> json) =>
      _$ApiV1ConsumptionLogsRequestBodySealedPlanItemLogFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$ApiV1ConsumptionLogsRequestBodySealedPlanItemLogToJson(this);
}
