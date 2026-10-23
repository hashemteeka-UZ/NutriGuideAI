// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alternative.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Alternative _$AlternativeFromJson(Map<String, dynamic> json) => Alternative(
  kcal: json['kcal'] as num,
  kcalDelta: json['kcal_delta'] as num,
  meal: MealSummary.fromJson(json['meal'] as Map<String, dynamic>),
  servingsMultiplier: json['servings_multiplier'] as num,
);

Map<String, dynamic> _$AlternativeToJson(Alternative instance) =>
    <String, dynamic>{
      'kcal': instance.kcal,
      'kcal_delta': instance.kcalDelta,
      'meal': instance.meal.toJson(),
      'servings_multiplier': instance.servingsMultiplier,
    };
