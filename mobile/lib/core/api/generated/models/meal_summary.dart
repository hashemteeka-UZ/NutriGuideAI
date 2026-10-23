// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dish_form.dart';
import 'meal_stance.dart';

part 'meal_summary.g.dart';

@JsonSerializable()
class MealSummary {
  const MealSummary({
    required this.allergens,
    required this.carbG,
    required this.fatG,
    required this.kcal,
    required this.mealId,
    required this.name,
    required this.proteinG,
    required this.servingGrams,
    required this.tags,
    this.cuisine,
    this.dishForm,
    this.myStance,
  });
  
  factory MealSummary.fromJson(Map<String, Object?> json) => _$MealSummaryFromJson(json);
  
  final List<String> allergens;
  @JsonKey(name: 'carb_g')
  final num carbG;
  final String? cuisine;
  @JsonKey(name: 'dish_form')
  final DishForm? dishForm;
  @JsonKey(name: 'fat_g')
  final num fatG;
  final num kcal;
  @JsonKey(name: 'meal_id')
  final int mealId;
  @JsonKey(name: 'my_stance')
  final MealStance? myStance;
  final String name;
  @JsonKey(name: 'protein_g')
  final num proteinG;
  @JsonKey(name: 'serving_grams')
  final num servingGrams;
  final List<String> tags;

  Map<String, Object?> toJson() => _$MealSummaryToJson(this);
}
