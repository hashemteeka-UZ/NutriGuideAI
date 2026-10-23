// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'weight_point.g.dart';

@JsonSerializable()
class WeightPoint {
  const WeightPoint({
    required this.measuredOn,
    required this.weightKg,
  });
  
  factory WeightPoint.fromJson(Map<String, Object?> json) => _$WeightPointFromJson(json);
  
  @JsonKey(name: 'measured_on')
  final DateTime measuredOn;
  @JsonKey(name: 'weight_kg')
  final num weightKg;

  Map<String, Object?> toJson() => _$WeightPointToJson(this);
}
