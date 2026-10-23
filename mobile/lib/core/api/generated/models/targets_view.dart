// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'screening.dart';
import 'target.dart';
import 'water_goal.dart';

part 'targets_view.g.dart';

@JsonSerializable()
class TargetsView {
  const TargetsView({
    required this.screening,
    required this.water,
    this.target,
  });
  
  factory TargetsView.fromJson(Map<String, Object?> json) => _$TargetsViewFromJson(json);
  
  final Screening screening;
  final Target? target;
  final WaterGoal water;

  Map<String, Object?> toJson() => _$TargetsViewToJson(this);
}
