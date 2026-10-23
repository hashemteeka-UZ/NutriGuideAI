// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consumption_log_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConsumptionLogOut _$ConsumptionLogOutFromJson(
  Map<String, dynamic> json,
) => ConsumptionLogOut(
  consumedAt: DateTime.parse(json['consumed_at'] as String),
  kind: ConsumptionLogOutKind.fromJson(json['kind'] as String),
  logDate: DateTime.parse(json['log_date'] as String),
  logId: (json['log_id'] as num).toInt(),
  name: json['name'] as String,
  nutrients: NutrientTotals.fromJson(json['nutrients'] as Map<String, dynamic>),
  status: ConsumptionLogOutStatus.fromJson(json['status'] as String),
  foodId: (json['food_id'] as num?)?.toInt(),
  gramsConsumed: json['grams_consumed'] as num?,
  mealId: (json['meal_id'] as num?)?.toInt(),
  planItemId: (json['plan_item_id'] as num?)?.toInt(),
  servingsConsumed: json['servings_consumed'] as num?,
  slot: json['slot'] == null ? null : MealSlot.fromJson(json['slot'] as String),
);

Map<String, dynamic> _$ConsumptionLogOutToJson(ConsumptionLogOut instance) =>
    <String, dynamic>{
      'consumed_at': instance.consumedAt.toIso8601String(),
      'food_id': instance.foodId,
      'grams_consumed': instance.gramsConsumed,
      'kind': instance.kind.toJson(),
      'log_date': instance.logDate.toIso8601String(),
      'log_id': instance.logId,
      'meal_id': instance.mealId,
      'name': instance.name,
      'nutrients': instance.nutrients.toJson(),
      'plan_item_id': instance.planItemId,
      'servings_consumed': instance.servingsConsumed,
      'slot': instance.slot?.toJson(),
      'status': instance.status.toJson(),
    };
