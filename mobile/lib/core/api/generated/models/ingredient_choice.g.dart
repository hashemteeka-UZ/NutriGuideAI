// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_choice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IngredientChoice _$IngredientChoiceFromJson(Map<String, dynamic> json) =>
    IngredientChoice(
      ingredientId: (json['ingredient_id'] as num).toInt(),
      stance: IngredientStance.fromJson(json['stance'] as String),
    );

Map<String, dynamic> _$IngredientChoiceToJson(IngredientChoice instance) =>
    <String, dynamic>{
      'ingredient_id': instance.ingredientId,
      'stance': instance.stance.toJson(),
    };
