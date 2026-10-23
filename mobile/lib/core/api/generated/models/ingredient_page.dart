// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'ingredient_hit.dart';

part 'ingredient_page.g.dart';

@JsonSerializable()
class IngredientPage {
  const IngredientPage({
    required this.items,
    required this.total,
  });
  
  factory IngredientPage.fromJson(Map<String, Object?> json) => _$IngredientPageFromJson(json);
  
  final List<IngredientHit> items;
  final int total;

  Map<String, Object?> toJson() => _$IngredientPageToJson(this);
}
