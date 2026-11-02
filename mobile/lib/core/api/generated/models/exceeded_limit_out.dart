// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'exceeded_limit_out.g.dart';

@JsonSerializable()
class ExceededLimitOut {
  const ExceededLimitOut({
    required this.limit,
    required this.nutrient,
    this.total,
  });
  
  factory ExceededLimitOut.fromJson(Map<String, Object?> json) => _$ExceededLimitOutFromJson(json);
  
  final num limit;
  final String nutrient;
  final num? total;

  Map<String, Object?> toJson() => _$ExceededLimitOutToJson(this);
}
