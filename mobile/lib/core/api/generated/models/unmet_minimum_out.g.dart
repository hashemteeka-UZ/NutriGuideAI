// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unmet_minimum_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnmetMinimumOut _$UnmetMinimumOutFromJson(Map<String, dynamic> json) =>
    UnmetMinimumOut(
      minimum: json['minimum'] as num,
      nutrient: json['nutrient'] as String,
      total: json['total'] as num?,
    );

Map<String, dynamic> _$UnmetMinimumOutToJson(UnmetMinimumOut instance) =>
    <String, dynamic>{
      'minimum': instance.minimum,
      'nutrient': instance.nutrient,
      'total': instance.total,
    };
