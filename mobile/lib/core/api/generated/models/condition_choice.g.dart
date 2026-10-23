// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'condition_choice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConditionChoice _$ConditionChoiceFromJson(Map<String, dynamic> json) =>
    ConditionChoice(
      code: json['code'] as String,
      severity: json['severity'] == null
          ? null
          : ConditionSeverity.fromJson(json['severity'] as String),
    );

Map<String, dynamic> _$ConditionChoiceToJson(ConditionChoice instance) =>
    <String, dynamic>{
      'code': instance.code,
      'severity': instance.severity?.toJson(),
    };
