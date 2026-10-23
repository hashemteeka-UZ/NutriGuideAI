// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exceeded_limit_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExceededLimitOut _$ExceededLimitOutFromJson(Map<String, dynamic> json) =>
    ExceededLimitOut(
      limit: json['limit'] as num,
      nutrient: json['nutrient'] as String,
      total: json['total'] as num?,
    );

Map<String, dynamic> _$ExceededLimitOutToJson(ExceededLimitOut instance) =>
    <String, dynamic>{
      'limit': instance.limit,
      'nutrient': instance.nutrient,
      'total': instance.total,
    };
