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
  category: json['category'] as String? ?? '',
  categoryCode: json['category_code'] as String? ?? '',
);

Map<String, dynamic> _$ShoppingItemToJson(ShoppingItem instance) =>
    <String, dynamic>{
      'category': instance.category,
      'category_code': instance.categoryCode,
      'grams': instance.grams,
      'ingredient_id': instance.ingredientId,
      'meals': instance.meals,
      'name': instance.name,
    };
