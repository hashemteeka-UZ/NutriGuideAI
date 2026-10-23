// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'ingredient_stance.dart';

part 'ingredient_choice.g.dart';

@JsonSerializable()
class IngredientChoice {
  const IngredientChoice({
    required this.ingredientId,
    required this.stance,
  });
  
  factory IngredientChoice.fromJson(Map<String, Object?> json) => _$IngredientChoiceFromJson(json);
  
  @JsonKey(name: 'ingredient_id')
  final int ingredientId;
  final IngredientStance stance;

  Map<String, Object?> toJson() => _$IngredientChoiceToJson(this);
}
