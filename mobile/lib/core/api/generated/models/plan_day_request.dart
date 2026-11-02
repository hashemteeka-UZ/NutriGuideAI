// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'plan_day_request.g.dart';

@JsonSerializable()
class PlanDayRequest {
  const PlanDayRequest({
    required this.date,
  });
  
  factory PlanDayRequest.fromJson(Map<String, Object?> json) => _$PlanDayRequestFromJson(json);
  
  final DateTime date;

  Map<String, Object?> toJson() => _$PlanDayRequestToJson(this);
}
