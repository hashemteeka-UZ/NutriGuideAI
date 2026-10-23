// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrient_amount.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NutrientAmount _$NutrientAmountFromJson(Map<String, dynamic> json) =>
    NutrientAmount(
      code: json['code'] as String,
      unit: NutrientUnit.fromJson(json['unit'] as String),
      per100g: json['per_100g'] as num?,
      perServing: json['per_serving'] as num?,
    );

Map<String, dynamic> _$NutrientAmountToJson(NutrientAmount instance) =>
    <String, dynamic>{
      'code': instance.code,
      'per_100g': instance.per100g,
      'per_serving': instance.perServing,
      'unit': instance.unit.toJson(),
    };
