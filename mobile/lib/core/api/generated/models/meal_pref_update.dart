// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meal_stance.dart';

part 'meal_pref_update.g.dart';

@JsonSerializable()
class MealPrefUpdate {
  const MealPrefUpdate({
    required this.stance,
  });
  
  factory MealPrefUpdate.fromJson(Map<String, Object?> json) => _$MealPrefUpdateFromJson(json);
  
  final MealStance stance;

  Map<String, Object?> toJson() => _$MealPrefUpdateToJson(this);
}
