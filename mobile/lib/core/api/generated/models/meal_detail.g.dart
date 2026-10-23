// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealDetail _$MealDetailFromJson(Map<String, dynamic> json) => MealDetail(
  allergens: (json['allergens'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  carbG: json['carb_g'] as num,
  datasetVersion: json['dataset_version'] as String,
  fatG: json['fat_g'] as num,
  ingredients: (json['ingredients'] as List<dynamic>)
      .map((e) => MealIngredientOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  kcal: json['kcal'] as num,
  mealId: (json['meal_id'] as num).toInt(),
  name: json['name'] as String,
  nutrients: (json['nutrients'] as List<dynamic>)
      .map((e) => NutrientAmount.fromJson(e as Map<String, dynamic>))
      .toList(),
  proteinG: json['protein_g'] as num,
  servingGrams: json['serving_grams'] as num,
  servings: (json['servings'] as num).toInt(),
  source: json['source'] as String,
  steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  totalGrams: json['total_grams'] as num,
  cuisine: json['cuisine'] as String?,
  dishForm: json['dish_form'] == null
      ? null
      : DishForm.fromJson(json['dish_form'] as String),
  myStance: json['my_stance'] == null
      ? null
      : MealStance.fromJson(json['my_stance'] as String),
);

Map<String, dynamic> _$MealDetailToJson(MealDetail instance) =>
    <String, dynamic>{
      'allergens': instance.allergens,
      'carb_g': instance.carbG,
      'cuisine': instance.cuisine,
      'dataset_version': instance.datasetVersion,
      'dish_form': instance.dishForm?.toJson(),
      'fat_g': instance.fatG,
      'ingredients': instance.ingredients.map((e) => e.toJson()).toList(),
      'kcal': instance.kcal,
      'meal_id': instance.mealId,
      'my_stance': instance.myStance?.toJson(),
      'name': instance.name,
      'nutrients': instance.nutrients.map((e) => e.toJson()).toList(),
      'protein_g': instance.proteinG,
      'serving_grams': instance.servingGrams,
      'servings': instance.servings,
      'source': instance.source,
      'steps': instance.steps,
      'tags': instance.tags,
      'total_grams': instance.totalGrams,
    };
