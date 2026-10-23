// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_v1_consumption_logs_request_body_sealed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$ApiV1ConsumptionLogsRequestBodySealedToJson(
  ApiV1ConsumptionLogsRequestBodySealed instance,
) => <String, dynamic>{};

ApiV1ConsumptionLogsRequestBodySealedFoodLog
_$ApiV1ConsumptionLogsRequestBodySealedFoodLogFromJson(
  Map<String, dynamic> json,
) => ApiV1ConsumptionLogsRequestBodySealedFoodLog(
  clientUuid: json['clientUuid'] as String,
  consumedAt: DateTime.parse(json['consumedAt'] as String),
  foodId: (json['foodId'] as num).toInt(),
  gramsConsumed: json['gramsConsumed'] as num,
  kind: json['kind'] as String,
  slot: json['slot'] == null ? null : MealSlot.fromJson(json['slot'] as String),
);

Map<String, dynamic> _$ApiV1ConsumptionLogsRequestBodySealedFoodLogToJson(
  ApiV1ConsumptionLogsRequestBodySealedFoodLog instance,
) => <String, dynamic>{
  'clientUuid': instance.clientUuid,
  'consumedAt': instance.consumedAt.toIso8601String(),
  'foodId': instance.foodId,
  'gramsConsumed': instance.gramsConsumed,
  'kind': instance.kind,
  'slot': instance.slot?.toJson(),
};

ApiV1ConsumptionLogsRequestBodySealedMealLog
_$ApiV1ConsumptionLogsRequestBodySealedMealLogFromJson(
  Map<String, dynamic> json,
) => ApiV1ConsumptionLogsRequestBodySealedMealLog(
  clientUuid: json['clientUuid'] as String,
  consumedAt: DateTime.parse(json['consumedAt'] as String),
  kind: json['kind'] as String,
  mealId: (json['mealId'] as num).toInt(),
  servingsConsumed: json['servingsConsumed'] as num,
  slot: json['slot'] == null ? null : MealSlot.fromJson(json['slot'] as String),
);

Map<String, dynamic> _$ApiV1ConsumptionLogsRequestBodySealedMealLogToJson(
  ApiV1ConsumptionLogsRequestBodySealedMealLog instance,
) => <String, dynamic>{
  'clientUuid': instance.clientUuid,
  'consumedAt': instance.consumedAt.toIso8601String(),
  'kind': instance.kind,
  'mealId': instance.mealId,
  'servingsConsumed': instance.servingsConsumed,
  'slot': instance.slot?.toJson(),
};

ApiV1ConsumptionLogsRequestBodySealedPlanItemLog
_$ApiV1ConsumptionLogsRequestBodySealedPlanItemLogFromJson(
  Map<String, dynamic> json,
) => ApiV1ConsumptionLogsRequestBodySealedPlanItemLog(
  clientUuid: json['clientUuid'] as String,
  consumedAt: DateTime.parse(json['consumedAt'] as String),
  kind: json['kind'] as String,
  planItemId: (json['planItemId'] as num).toInt(),
  servingsConsumed: json['servingsConsumed'] as num,
);

Map<String, dynamic> _$ApiV1ConsumptionLogsRequestBodySealedPlanItemLogToJson(
  ApiV1ConsumptionLogsRequestBodySealedPlanItemLog instance,
) => <String, dynamic>{
  'clientUuid': instance.clientUuid,
  'consumedAt': instance.consumedAt.toIso8601String(),
  'kind': instance.kind,
  'planItemId': instance.planItemId,
  'servingsConsumed': instance.servingsConsumed,
};
