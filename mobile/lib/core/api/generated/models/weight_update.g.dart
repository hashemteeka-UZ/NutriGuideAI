// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeightUpdate _$WeightUpdateFromJson(Map<String, dynamic> json) => WeightUpdate(
  updatedAt: DateTime.parse(json['updated_at'] as String),
  weightKg: json['weight_kg'] as num,
);

Map<String, dynamic> _$WeightUpdateToJson(WeightUpdate instance) =>
    <String, dynamic>{
      'updated_at': instance.updatedAt.toIso8601String(),
      'weight_kg': instance.weightKg,
    };
