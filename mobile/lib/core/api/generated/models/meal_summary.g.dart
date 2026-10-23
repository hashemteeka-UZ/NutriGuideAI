// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealSummary _$MealSummaryFromJson(Map<String, dynamic> json) => MealSummary(
  allergens: (json['allergens'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  carbG: json['carb_g'] as num,
  fatG: json['fat_g'] as num,
  kcal: json['kcal'] as num,
  mealId: (json['meal_id'] as num).toInt(),
  name: json['name'] as String,
  proteinG: json['protein_g'] as num,
  servingGrams: json['serving_grams'] as num,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  cuisine: json['cuisine'] as String?,
  dishForm: json['dish_form'] == null
      ? null
      : DishForm.fromJson(json['dish_form'] as String),
  myStance: json['my_stance'] == null
      ? null
      : MealStance.fromJson(json['my_stance'] as String),
);

Map<String, dynamic> _$MealSummaryToJson(MealSummary instance) =>
    <String, dynamic>{
      'allergens': instance.allergens,
      'carb_g': instance.carbG,
      'cuisine': instance.cuisine,
      'dish_form': instance.dishForm?.toJson(),
      'fat_g': instance.fatG,
      'kcal': instance.kcal,
      'meal_id': instance.mealId,
      'my_stance': instance.myStance?.toJson(),
      'name': instance.name,
      'protein_g': instance.proteinG,
      'serving_grams': instance.servingGrams,
      'tags': instance.tags,
    };
