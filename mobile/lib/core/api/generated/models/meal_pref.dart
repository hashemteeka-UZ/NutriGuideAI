// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meal_stance.dart';

part 'meal_pref.g.dart';

@JsonSerializable()
class MealPref {
  const MealPref({
    required this.mealId,
    required this.stance,
    required this.updatedAt,
  });
  
  factory MealPref.fromJson(Map<String, Object?> json) => _$MealPrefFromJson(json);
  
  @JsonKey(name: 'meal_id')
  final int mealId;
  final MealStance stance;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$MealPrefToJson(this);
}
