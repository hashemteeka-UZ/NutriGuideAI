// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingItem _$ShoppingItemFromJson(Map<String, dynamic> json) => ShoppingItem(
  grams: json['grams'] as num,
  ingredientId: (json['ingredient_id'] as num).toInt(),
  meals: (json['meals'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$ShoppingItemToJson(ShoppingItem instance) =>
    <String, dynamic>{
      'grams': instance.grams,
      'ingredient_id': instance.ingredientId,
      'meals': instance.meals,
      'name': instance.name,
    };
