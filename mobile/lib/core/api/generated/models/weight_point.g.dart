// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeightPoint _$WeightPointFromJson(Map<String, dynamic> json) => WeightPoint(
  measuredOn: DateTime.parse(json['measured_on'] as String),
  weightKg: json['weight_kg'] as num,
);

Map<String, dynamic> _$WeightPointToJson(WeightPoint instance) =>
    <String, dynamic>{
      'measured_on': instance.measuredOn.toIso8601String(),
      'weight_kg': instance.weightKg,
    };
