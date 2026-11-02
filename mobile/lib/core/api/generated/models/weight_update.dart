// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'weight_update.g.dart';

@JsonSerializable()
class WeightUpdate {
  const WeightUpdate({
    required this.updatedAt,
    required this.weightKg,
  });
  
  factory WeightUpdate.fromJson(Map<String, Object?> json) => _$WeightUpdateFromJson(json);
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'weight_kg')
  final num weightKg;

  Map<String, Object?> toJson() => _$WeightUpdateToJson(this);
}
