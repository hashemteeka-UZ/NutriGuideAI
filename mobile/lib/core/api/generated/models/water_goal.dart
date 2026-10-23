// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'water_goal_source.dart';

part 'water_goal.g.dart';

@JsonSerializable()
class WaterGoal {
  const WaterGoal({
    required this.remindersDefaultOff,
    required this.requiresClinician,
    required this.source,
    this.goalMl,
  });
  
  factory WaterGoal.fromJson(Map<String, Object?> json) => _$WaterGoalFromJson(json);
  
  @JsonKey(name: 'goal_ml')
  final int? goalMl;
  @JsonKey(name: 'reminders_default_off')
  final bool remindersDefaultOff;
  @JsonKey(name: 'requires_clinician')
  final bool requiresClinician;
  final WaterGoalSource source;

  Map<String, Object?> toJson() => _$WaterGoalToJson(this);
}
