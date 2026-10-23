// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allergen_choice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllergenChoice _$AllergenChoiceFromJson(Map<String, dynamic> json) =>
    AllergenChoice(
      code: json['code'] as String,
      severity: AllergenSeverity.fromJson(json['severity'] as String),
    );

Map<String, dynamic> _$AllergenChoiceToJson(AllergenChoice instance) =>
    <String, dynamic>{
      'code': instance.code,
      'severity': instance.severity.toJson(),
    };
