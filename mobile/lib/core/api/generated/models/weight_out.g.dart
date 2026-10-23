// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeightOut _$WeightOutFromJson(Map<String, dynamic> json) => WeightOut(
  goalReached: json['goal_reached'] as bool,
  measuredOn: DateTime.parse(json['measured_on'] as String),
  status: WeightOutStatus.fromJson(json['status'] as String),
  targetStatus: WeightOutTargetStatus.fromJson(json['target_status'] as String),
  weightKg: json['weight_kg'] as num,
  newTargetId: (json['new_target_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$WeightOutToJson(WeightOut instance) => <String, dynamic>{
  'goal_reached': instance.goalReached,
  'measured_on': instance.measuredOn.toIso8601String(),
  'new_target_id': instance.newTargetId,
  'status': instance.status.toJson(),
  'target_status': instance.targetStatus.toJson(),
  'weight_kg': instance.weightKg,
};
