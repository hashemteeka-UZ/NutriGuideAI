// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'meal_ingredient_out.g.dart';

@JsonSerializable()
class MealIngredientOut {
  const MealIngredientOut({
    required this.gramsPerServing,
    required this.ingredientId,
    required this.isOptional,
    required this.name,
  });
  
  factory MealIngredientOut.fromJson(Map<String, Object?> json) => _$MealIngredientOutFromJson(json);
  
  @JsonKey(name: 'grams_per_serving')
  final num gramsPerServing;
  @JsonKey(name: 'ingredient_id')
  final int ingredientId;
  @JsonKey(name: 'is_optional')
  final bool isOptional;
  final String name;

  Map<String, Object?> toJson() => _$MealIngredientOutToJson(this);
}
