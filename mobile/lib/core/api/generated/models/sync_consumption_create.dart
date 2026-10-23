// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sync_consumption_create.g.dart';

@JsonSerializable()
class SyncConsumptionCreate {
  const SyncConsumptionCreate({
    required this.log,
    required this.op,
    required this.opId,
  });
  
  factory SyncConsumptionCreate.fromJson(Map<String, Object?> json) => _$SyncConsumptionCreateFromJson(json);
  
  final SyncConsumptionCreateLogSealed log;
  final String op;
  @JsonKey(name: 'op_id')
  final String opId;

  Map<String, Object?> toJson() => _$SyncConsumptionCreateToJson(this);
}
