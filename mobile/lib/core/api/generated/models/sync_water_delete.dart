// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sync_water_delete.g.dart';

@JsonSerializable()
class SyncWaterDelete {
  const SyncWaterDelete({
    required this.logId,
    required this.op,
    required this.opId,
  });
  
  factory SyncWaterDelete.fromJson(Map<String, Object?> json) => _$SyncWaterDeleteFromJson(json);
  
  @JsonKey(name: 'log_id')
  final int logId;
  final String op;
  @JsonKey(name: 'op_id')
  final String opId;

  Map<String, Object?> toJson() => _$SyncWaterDeleteToJson(this);
}
