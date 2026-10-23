// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodLog _$FoodLogFromJson(Map<String, dynamic> json) => FoodLog(
  clientUuid: json['client_uuid'] as String,
  consumedAt: DateTime.parse(json['consumed_at'] as String),
  foodId: (json['food_id'] as num).toInt(),
  gramsConsumed: json['grams_consumed'] as num,
  kind: json['kind'] as String,
  slot: json['slot'] == null ? null : MealSlot.fromJson(json['slot'] as String),
);

Map<String, dynamic> _$FoodLogToJson(FoodLog instance) => <String, dynamic>{
  'client_uuid': instance.clientUuid,
  'consumed_at': instance.consumedAt.toIso8601String(),
  'food_id': instance.foodId,
  'grams_consumed': instance.gramsConsumed,
  'kind': instance.kind,
  'slot': instance.slot?.toJson(),
};
