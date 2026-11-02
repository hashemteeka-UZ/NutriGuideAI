// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'condition_severity.dart';

part 'condition_choice.g.dart';

@JsonSerializable()
class ConditionChoice {
  const ConditionChoice({
    required this.code,
    this.severity,
  });
  
  factory ConditionChoice.fromJson(Map<String, Object?> json) => _$ConditionChoiceFromJson(json);
  
  final String code;
  final ConditionSeverity? severity;

  Map<String, Object?> toJson() => _$ConditionChoiceToJson(this);
}
