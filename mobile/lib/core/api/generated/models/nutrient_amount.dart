// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'nutrient_unit.dart';

part 'nutrient_amount.g.dart';

@JsonSerializable()
class NutrientAmount {
  const NutrientAmount({
    required this.code,
    required this.unit,
    this.per100g,
    this.perServing,
  });
  
  factory NutrientAmount.fromJson(Map<String, Object?> json) => _$NutrientAmountFromJson(json);
  
  final String code;
  @JsonKey(name: 'per_100g')
  final num? per100g;
  @JsonKey(name: 'per_serving')
  final num? perServing;
  final NutrientUnit unit;

  Map<String, Object?> toJson() => _$NutrientAmountToJson(this);
}
