// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'targets_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TargetsView _$TargetsViewFromJson(Map<String, dynamic> json) => TargetsView(
  screening: Screening.fromJson(json['screening'] as Map<String, dynamic>),
  water: WaterGoal.fromJson(json['water'] as Map<String, dynamic>),
  target: json['target'] == null
      ? null
      : Target.fromJson(json['target'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TargetsViewToJson(TargetsView instance) =>
    <String, dynamic>{
      'screening': instance.screening.toJson(),
      'target': instance.target?.toJson(),
      'water': instance.water.toJson(),
    };
