// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'water_goal.dart';
import 'water_log_out.dart';

part 'water_day.g.dart';

@JsonSerializable()
class WaterDay {
  const WaterDay({
    required this.date,
    required this.goal,
    required this.logs,
    required this.totalMl,
  });
  
  factory WaterDay.fromJson(Map<String, Object?> json) => _$WaterDayFromJson(json);
  
  final DateTime date;
  final WaterGoal goal;
  final List<WaterLogOut> logs;
  @JsonKey(name: 'total_ml')
  final int totalMl;

  Map<String, Object?> toJson() => _$WaterDayToJson(this);
}
