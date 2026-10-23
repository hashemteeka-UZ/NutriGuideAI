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
  });
  
  factory ShoppingItem.fromJson(Map<String, Object?> json) => _$ShoppingItemFromJson(json);
  
  final num grams;
  @JsonKey(name: 'ingredient_id')
  final int ingredientId;
  final int meals;
  final String name;

  Map<String, Object?> toJson() => _$ShoppingItemToJson(this);
}
