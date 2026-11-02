// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dish_form.dart';
import 'meal_ingredient_out.dart';
import 'meal_stance.dart';
import 'nutrient_amount.dart';

part 'meal_detail.g.dart';

@JsonSerializable()
class MealDetail {
  const MealDetail({
    required this.allergens,
    required this.carbG,
    required this.datasetVersion,
    required this.fatG,
    required this.ingredients,
    required this.kcal,
    required this.mealId,
    required this.name,
    required this.nutrients,
    required this.proteinG,
    required this.servingGrams,
    required this.servings,
    required this.source,
    required this.steps,
    required this.tags,
    required this.totalGrams,
    this.cuisine,
    this.dishForm,
    this.myStance,
  });
  
  factory MealDetail.fromJson(Map<String, Object?> json) => _$MealDetailFromJson(json);
  
  final List<String> allergens;
  @JsonKey(name: 'carb_g')
  final num carbG;
  final String? cuisine;
  @JsonKey(name: 'dataset_version')
  final String datasetVersion;
  @JsonKey(name: 'dish_form')
  final DishForm? dishForm;
  @JsonKey(name: 'fat_g')
  final num fatG;
  final List<MealIngredientOut> ingredients;
  final num kcal;
  @JsonKey(name: 'meal_id')
  final int mealId;
  @JsonKey(name: 'my_stance')
  final MealStance? myStance;
  final String name;
  final List<NutrientAmount> nutrients;
  @JsonKey(name: 'protein_g')
  final num proteinG;
  @JsonKey(name: 'serving_grams')
  final num servingGrams;
  final int servings;
  final String source;
  final List<String> steps;
  final List<String> tags;
  @JsonKey(name: 'total_grams')
  final num totalGrams;

  Map<String, Object?> toJson() => _$MealDetailToJson(this);
}
