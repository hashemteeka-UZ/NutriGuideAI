// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sync_consumption_delete.g.dart';

@JsonSerializable()
class SyncConsumptionDelete {
  const SyncConsumptionDelete({
    required this.logId,
    required this.op,
    required this.opId,
  });
  
  factory SyncConsumptionDelete.fromJson(Map<String, Object?> json) => _$SyncConsumptionDeleteFromJson(json);
  
  @JsonKey(name: 'log_id')
  final int logId;
  final String op;
  @JsonKey(name: 'op_id')
  final String opId;

  Map<String, Object?> toJson() => _$SyncConsumptionDeleteToJson(this);
}
