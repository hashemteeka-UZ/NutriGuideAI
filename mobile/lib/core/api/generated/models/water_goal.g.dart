// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaterGoal _$WaterGoalFromJson(Map<String, dynamic> json) => WaterGoal(
  remindersDefaultOff: json['reminders_default_off'] as bool,
  requiresClinician: json['requires_clinician'] as bool,
  source: WaterGoalSource.fromJson(json['source'] as String),
  goalMl: (json['goal_ml'] as num?)?.toInt(),
);

Map<String, dynamic> _$WaterGoalToJson(WaterGoal instance) => <String, dynamic>{
  'goal_ml': instance.goalMl,
  'reminders_default_off': instance.remindersDefaultOff,
  'requires_clinician': instance.requiresClinician,
  'source': instance.source.toJson(),
};
