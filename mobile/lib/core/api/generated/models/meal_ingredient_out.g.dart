// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_ingredient_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealIngredientOut _$MealIngredientOutFromJson(Map<String, dynamic> json) =>
    MealIngredientOut(
      gramsPerServing: json['grams_per_serving'] as num,
      ingredientId: (json['ingredient_id'] as num).toInt(),
      isOptional: json['is_optional'] as bool,
      name: json['name'] as String,
    );

Map<String, dynamic> _$MealIngredientOutToJson(MealIngredientOut instance) =>
    <String, dynamic>{
      'grams_per_serving': instance.gramsPerServing,
      'ingredient_id': instance.ingredientId,
      'is_optional': instance.isOptional,
      'name': instance.name,
    };
