// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'ingredient_hit.g.dart';

@JsonSerializable()
class IngredientHit {
  const IngredientHit({
    required this.code,
    required this.ingredientId,
    required this.name,
    this.foodId,
  });
  
  factory IngredientHit.fromJson(Map<String, Object?> json) => _$IngredientHitFromJson(json);
  
  final String code;
  @JsonKey(name: 'food_id')
  final int? foodId;
  @JsonKey(name: 'ingredient_id')
  final int ingredientId;
  final String name;

  Map<String, Object?> toJson() => _$IngredientHitToJson(this);
}
