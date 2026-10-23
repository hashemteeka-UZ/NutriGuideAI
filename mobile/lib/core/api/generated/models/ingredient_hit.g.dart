// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_hit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IngredientHit _$IngredientHitFromJson(Map<String, dynamic> json) =>
    IngredientHit(
      code: json['code'] as String,
      ingredientId: (json['ingredient_id'] as num).toInt(),
      name: json['name'] as String,
      foodId: (json['food_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$IngredientHitToJson(IngredientHit instance) =>
    <String, dynamic>{
      'code': instance.code,
      'food_id': instance.foodId,
      'ingredient_id': instance.ingredientId,
      'name': instance.name,
    };
