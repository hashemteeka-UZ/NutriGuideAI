// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'condition_ref.g.dart';

@JsonSerializable()
class ConditionRef {
  const ConditionRef({
    required this.code,
    required this.fluidGoalRequiresClinician,
    required this.isSupported,
    required this.name,
  });
  
  factory ConditionRef.fromJson(Map<String, Object?> json) => _$ConditionRefFromJson(json);
  
  final String code;
  @JsonKey(name: 'fluid_goal_requires_clinician')
  final bool fluidGoalRequiresClinician;
  @JsonKey(name: 'is_supported')
  final bool isSupported;
  final String name;

  Map<String, Object?> toJson() => _$ConditionRefToJson(this);
}
