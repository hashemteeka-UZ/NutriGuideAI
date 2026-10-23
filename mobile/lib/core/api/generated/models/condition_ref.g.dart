// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'condition_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConditionRef _$ConditionRefFromJson(Map<String, dynamic> json) => ConditionRef(
  code: json['code'] as String,
  fluidGoalRequiresClinician: json['fluid_goal_requires_clinician'] as bool,
  isSupported: json['is_supported'] as bool,
  name: json['name'] as String,
);

Map<String, dynamic> _$ConditionRefToJson(ConditionRef instance) =>
    <String, dynamic>{
      'code': instance.code,
      'fluid_goal_requires_clinician': instance.fluidGoalRequiresClinician,
      'is_supported': instance.isSupported,
      'name': instance.name,
    };
