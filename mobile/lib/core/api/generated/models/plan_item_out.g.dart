// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_item_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanItemOut _$PlanItemOutFromJson(Map<String, dynamic> json) => PlanItemOut(
  carbG: json['carb_g'] as num,
  fatG: json['fat_g'] as num,
  grams: json['grams'] as num,
  kcal: json['kcal'] as num,
  logged: json['logged'] as bool,
  meal: MealSummary.fromJson(json['meal'] as Map<String, dynamic>),
  planItemId: (json['plan_item_id'] as num).toInt(),
  proteinG: json['protein_g'] as num,
  reasonCodes: (json['reason_codes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  servingsMultiplier: json['servings_multiplier'] as num,
  slot: MealSlot.fromJson(json['slot'] as String),
  wasSwapped: json['was_swapped'] as bool,
);

Map<String, dynamic> _$PlanItemOutToJson(PlanItemOut instance) =>
    <String, dynamic>{
      'carb_g': instance.carbG,
      'fat_g': instance.fatG,
      'grams': instance.grams,
      'kcal': instance.kcal,
      'logged': instance.logged,
      'meal': instance.meal.toJson(),
      'plan_item_id': instance.planItemId,
      'protein_g': instance.proteinG,
      'reason_codes': instance.reasonCodes,
      'servings_multiplier': instance.servingsMultiplier,
      'slot': instance.slot.toJson(),
      'was_swapped': instance.wasSwapped,
    };
