// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_consumption_create_log_sealed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$SyncConsumptionCreateLogSealedToJson(
  SyncConsumptionCreateLogSealed instance,
) => <String, dynamic>{};

SyncConsumptionCreateLogSealedFoodLog
_$SyncConsumptionCreateLogSealedFoodLogFromJson(Map<String, dynamic> json) =>
    SyncConsumptionCreateLogSealedFoodLog(
      clientUuid: json['clientUuid'] as String,
      consumedAt: DateTime.parse(json['consumedAt'] as String),
      foodId: (json['foodId'] as num).toInt(),
      gramsConsumed: json['gramsConsumed'] as num,
      kind: json['kind'] as String,
      slot: json['slot'] == null
          ? null
          : MealSlot.fromJson(json['slot'] as String),
    );

Map<String, dynamic> _$SyncConsumptionCreateLogSealedFoodLogToJson(
  SyncConsumptionCreateLogSealedFoodLog instance,
) => <String, dynamic>{
  'clientUuid': instance.clientUuid,
  'consumedAt': instance.consumedAt.toIso8601String(),
  'foodId': instance.foodId,
  'gramsConsumed': instance.gramsConsumed,
  'kind': instance.kind,
  'slot': instance.slot?.toJson(),
};

SyncConsumptionCreateLogSealedMealLog
_$SyncConsumptionCreateLogSealedMealLogFromJson(Map<String, dynamic> json) =>
    SyncConsumptionCreateLogSealedMealLog(
      clientUuid: json['clientUuid'] as String,
      consumedAt: DateTime.parse(json['consumedAt'] as String),
      kind: json['kind'] as String,
      mealId: (json['mealId'] as num).toInt(),
      servingsConsumed: json['servingsConsumed'] as num,
      slot: json['slot'] == null
          ? null
          : MealSlot.fromJson(json['slot'] as String),
    );

Map<String, dynamic> _$SyncConsumptionCreateLogSealedMealLogToJson(
  SyncConsumptionCreateLogSealedMealLog instance,
) => <String, dynamic>{
  'clientUuid': instance.clientUuid,
  'consumedAt': instance.consumedAt.toIso8601String(),
  'kind': instance.kind,
  'mealId': instance.mealId,
  'servingsConsumed': instance.servingsConsumed,
  'slot': instance.slot?.toJson(),
};

SyncConsumptionCreateLogSealedPlanItemLog
_$SyncConsumptionCreateLogSealedPlanItemLogFromJson(
  Map<String, dynamic> json,
) => SyncConsumptionCreateLogSealedPlanItemLog(
  clientUuid: json['clientUuid'] as String,
  consumedAt: DateTime.parse(json['consumedAt'] as String),
  kind: json['kind'] as String,
  planItemId: (json['planItemId'] as num).toInt(),
  servingsConsumed: json['servingsConsumed'] as num,
);

Map<String, dynamic> _$SyncConsumptionCreateLogSealedPlanItemLogToJson(
  SyncConsumptionCreateLogSealedPlanItemLog instance,
) => <String, dynamic>{
  'clientUuid': instance.clientUuid,
  'consumedAt': instance.consumedAt.toIso8601String(),
  'kind': instance.kind,
  'planItemId': instance.planItemId,
  'servingsConsumed': instance.servingsConsumed,
};
