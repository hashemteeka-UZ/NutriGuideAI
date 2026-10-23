// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
  activityLevel: ActivityLevel.fromJson(json['activity_level'] as String),
  allergens: (json['allergens'] as List<dynamic>)
      .map((e) => AllergenChoice.fromJson(e as Map<String, dynamic>))
      .toList(),
  birthDate: DateTime.parse(json['birth_date'] as String),
  conditions: (json['conditions'] as List<dynamic>)
      .map((e) => ConditionChoice.fromJson(e as Map<String, dynamic>))
      .toList(),
  cuisines: (json['cuisines'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  goalType: GoalType.fromJson(json['goal_type'] as String),
  heightCm: json['height_cm'] as num,
  ingredientPrefs: (json['ingredient_prefs'] as List<dynamic>)
      .map((e) => IngredientChoice.fromJson(e as Map<String, dynamic>))
      .toList(),
  sex: Sex.fromJson(json['sex'] as String),
  sleepTime: json['sleep_time'] as String,
  timezone: json['timezone'] as String,
  wakeTime: json['wake_time'] as String,
  latestWeightKg: json['latest_weight_kg'] as num?,
  latestWeightOn: json['latest_weight_on'] == null
      ? null
      : DateTime.parse(json['latest_weight_on'] as String),
  targetWeightKg: json['target_weight_kg'] as num?,
  waterGoalMl: (json['water_goal_ml'] as num?)?.toInt(),
  weeklyRateKg: json['weekly_rate_kg'] as num?,
);

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'activity_level': instance.activityLevel.toJson(),
  'allergens': instance.allergens.map((e) => e.toJson()).toList(),
  'birth_date': instance.birthDate.toIso8601String(),
  'conditions': instance.conditions.map((e) => e.toJson()).toList(),
  'cuisines': instance.cuisines,
  'goal_type': instance.goalType.toJson(),
  'height_cm': instance.heightCm,
  'ingredient_prefs': instance.ingredientPrefs.map((e) => e.toJson()).toList(),
  'latest_weight_kg': instance.latestWeightKg,
  'latest_weight_on': instance.latestWeightOn?.toIso8601String(),
  'sex': instance.sex.toJson(),
  'sleep_time': instance.sleepTime,
  'target_weight_kg': instance.targetWeightKg,
  'timezone': instance.timezone,
  'wake_time': instance.wakeTime,
  'water_goal_ml': instance.waterGoalMl,
  'weekly_rate_kg': instance.weeklyRateKg,
};
