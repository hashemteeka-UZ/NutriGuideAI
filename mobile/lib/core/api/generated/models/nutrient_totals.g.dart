// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrient_totals.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NutrientTotals _$NutrientTotalsFromJson(Map<String, dynamic> json) =>
    NutrientTotals(
      carbG: json['carb_g'] as num?,
      fatG: json['fat_g'] as num?,
      fiberG: json['fiber_g'] as num?,
      kcal: json['kcal'] as num?,
      proteinG: json['protein_g'] as num?,
      saturatedFatG: json['saturated_fat_g'] as num?,
      sodiumMg: json['sodium_mg'] as num?,
      sugarsG: json['sugars_g'] as num?,
    );

Map<String, dynamic> _$NutrientTotalsToJson(NutrientTotals instance) =>
    <String, dynamic>{
      'carb_g': instance.carbG,
      'fat_g': instance.fatG,
      'fiber_g': instance.fiberG,
      'kcal': instance.kcal,
      'protein_g': instance.proteinG,
      'saturated_fat_g': instance.saturatedFatG,
      'sodium_mg': instance.sodiumMg,
      'sugars_g': instance.sugarsG,
    };
