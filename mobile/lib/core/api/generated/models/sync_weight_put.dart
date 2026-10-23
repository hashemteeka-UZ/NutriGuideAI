// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sync_weight_put.g.dart';

@JsonSerializable()
class SyncWeightPut {
  const SyncWeightPut({
    required this.measuredOn,
    required this.op,
    required this.opId,
    required this.updatedAt,
    required this.weightKg,
  });
  
  factory SyncWeightPut.fromJson(Map<String, Object?> json) => _$SyncWeightPutFromJson(json);
  
  @JsonKey(name: 'measured_on')
  final DateTime measuredOn;
  final String op;
  @JsonKey(name: 'op_id')
  final String opId;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'weight_kg')
  final num weightKg;

  Map<String, Object?> toJson() => _$SyncWeightPutToJson(this);
}
