// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shopping_item.g.dart';

@JsonSerializable()
class ShoppingItem {
  const ShoppingItem({
    required this.grams,
    required this.ingredientId,
    required this.meals,
    required this.name,
    this.category = '',
    this.categoryCode = '',
  });
  
  factory ShoppingItem.fromJson(Map<String, Object?> json) => _$ShoppingItemFromJson(json);
  
  /// Food group name in the request language (Arabic for lang=ar, English otherwise). Empty when the food has no group. Items are sorted by category_code, then name.
  final String category;

  /// USDA SR Legacy food group code of the ingredient's food, for example 1100 for vegetables. Empty when the food has no SR Legacy group. Added in 1.2.0.
  @JsonKey(name: 'category_code')
  final String categoryCode;
  final num grams;
  @JsonKey(name: 'ingredient_id')
  final int ingredientId;
  final int meals;
  final String name;

  Map<String, Object?> toJson() => _$ShoppingItemToJson(this);
}
