// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meal_summary.dart';

part 'alternative.g.dart';

@JsonSerializable()
class Alternative {
  const Alternative({
    required this.kcal,
    required this.kcalDelta,
    required this.meal,
    required this.servingsMultiplier,
  });
  
  factory Alternative.fromJson(Map<String, Object?> json) => _$AlternativeFromJson(json);
  
  final num kcal;
  @JsonKey(name: 'kcal_delta')
  final num kcalDelta;
  final MealSummary meal;
  @JsonKey(name: 'servings_multiplier')
  final num servingsMultiplier;

  Map<String, Object?> toJson() => _$AlternativeToJson(this);
}
