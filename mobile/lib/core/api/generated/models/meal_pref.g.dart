// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_pref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealPref _$MealPrefFromJson(Map<String, dynamic> json) => MealPref(
  mealId: (json['meal_id'] as num).toInt(),
  stance: MealStance.fromJson(json['stance'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$MealPrefToJson(MealPref instance) => <String, dynamic>{
  'meal_id': instance.mealId,
  'stance': instance.stance.toJson(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
