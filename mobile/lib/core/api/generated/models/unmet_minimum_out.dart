// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'unmet_minimum_out.g.dart';

@JsonSerializable()
class UnmetMinimumOut {
  const UnmetMinimumOut({
    required this.minimum,
    required this.nutrient,
    this.total,
  });
  
  factory UnmetMinimumOut.fromJson(Map<String, Object?> json) => _$UnmetMinimumOutFromJson(json);
  
  final num minimum;
  final String nutrient;
  final num? total;

  Map<String, Object?> toJson() => _$UnmetMinimumOutToJson(this);
}
