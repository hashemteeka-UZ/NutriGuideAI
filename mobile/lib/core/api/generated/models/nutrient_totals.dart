// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'nutrient_totals.g.dart';

@JsonSerializable()
class NutrientTotals {
  const NutrientTotals({
    this.carbG,
    this.fatG,
    this.fiberG,
    this.kcal,
    this.proteinG,
    this.saturatedFatG,
    this.sodiumMg,
    this.sugarsG,
  });
  
  factory NutrientTotals.fromJson(Map<String, Object?> json) => _$NutrientTotalsFromJson(json);
  
  @JsonKey(name: 'carb_g')
  final num? carbG;
  @JsonKey(name: 'fat_g')
  final num? fatG;
  @JsonKey(name: 'fiber_g')
  final num? fiberG;
  final num? kcal;
  @JsonKey(name: 'protein_g')
  final num? proteinG;
  @JsonKey(name: 'saturated_fat_g')
  final num? saturatedFatG;
  @JsonKey(name: 'sodium_mg')
  final num? sodiumMg;
  @JsonKey(name: 'sugars_g')
  final num? sugarsG;

  Map<String, Object?> toJson() => _$NutrientTotalsToJson(this);
}
