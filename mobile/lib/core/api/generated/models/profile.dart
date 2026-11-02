// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'activity_level.dart';
import 'allergen_choice.dart';
import 'condition_choice.dart';
import 'goal_type.dart';
import 'ingredient_choice.dart';
import 'sex.dart';

part 'profile.g.dart';

@JsonSerializable()
class Profile {
  const Profile({
    required this.activityLevel,
    required this.allergens,
    required this.birthDate,
    required this.conditions,
    required this.cuisines,
    required this.goalType,
    required this.heightCm,
    required this.ingredientPrefs,
    required this.sex,
    required this.sleepTime,
    required this.timezone,
    required this.wakeTime,
    this.latestWeightKg,
    this.latestWeightOn,
    this.targetWeightKg,
    this.waterGoalMl,
    this.weeklyRateKg,
  });
  
  factory Profile.fromJson(Map<String, Object?> json) => _$ProfileFromJson(json);
  
  @JsonKey(name: 'activity_level')
  final ActivityLevel activityLevel;
  final List<AllergenChoice> allergens;
  @JsonKey(name: 'birth_date')
  final DateTime birthDate;
  final List<ConditionChoice> conditions;
  final List<String> cuisines;
  @JsonKey(name: 'goal_type')
  final GoalType goalType;
  @JsonKey(name: 'height_cm')
  final num heightCm;
  @JsonKey(name: 'ingredient_prefs')
  final List<IngredientChoice> ingredientPrefs;
  @JsonKey(name: 'latest_weight_kg')
  final num? latestWeightKg;
  @JsonKey(name: 'latest_weight_on')
  final DateTime? latestWeightOn;
  final Sex sex;
  @JsonKey(name: 'sleep_time')
  final String sleepTime;
  @JsonKey(name: 'target_weight_kg')
  final num? targetWeightKg;
  final String timezone;
  @JsonKey(name: 'wake_time')
  final String wakeTime;
  @JsonKey(name: 'water_goal_ml')
  final int? waterGoalMl;
  @JsonKey(name: 'weekly_rate_kg')
  final num? weeklyRateKg;

  Map<String, Object?> toJson() => _$ProfileToJson(this);
}
