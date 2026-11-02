// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'weight_out_status.dart';
import 'weight_out_target_status.dart';

part 'weight_out.g.dart';

@JsonSerializable()
class WeightOut {
  const WeightOut({
    required this.goalReached,
    required this.measuredOn,
    required this.status,
    required this.targetStatus,
    required this.weightKg,
    this.newTargetId,
  });
  
  factory WeightOut.fromJson(Map<String, Object?> json) => _$WeightOutFromJson(json);
  
  @JsonKey(name: 'goal_reached')
  final bool goalReached;
  @JsonKey(name: 'measured_on')
  final DateTime measuredOn;
  @JsonKey(name: 'new_target_id')
  final int? newTargetId;
  final WeightOutStatus status;
  @JsonKey(name: 'target_status')
  final WeightOutTargetStatus targetStatus;
  @JsonKey(name: 'weight_kg')
  final num weightKg;

  Map<String, Object?> toJson() => _$WeightOutToJson(this);
}
