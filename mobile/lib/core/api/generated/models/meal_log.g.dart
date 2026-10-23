// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealLog _$MealLogFromJson(Map<String, dynamic> json) => MealLog(
  clientUuid: json['client_uuid'] as String,
  consumedAt: DateTime.parse(json['consumed_at'] as String),
  kind: json['kind'] as String,
  mealId: (json['meal_id'] as num).toInt(),
  servingsConsumed: json['servings_consumed'] as num,
  slot: json['slot'] == null ? null : MealSlot.fromJson(json['slot'] as String),
);

Map<String, dynamic> _$MealLogToJson(MealLog instance) => <String, dynamic>{
  'client_uuid': instance.clientUuid,
  'consumed_at': instance.consumedAt.toIso8601String(),
  'kind': instance.kind,
  'meal_id': instance.mealId,
  'servings_consumed': instance.servingsConsumed,
  'slot': instance.slot?.toJson(),
};
