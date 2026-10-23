// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sync_water_create.g.dart';

@JsonSerializable()
class SyncWaterCreate {
  const SyncWaterCreate({
    required this.amountMl,
    required this.clientUuid,
    required this.consumedAt,
    required this.op,
    required this.opId,
  });
  
  factory SyncWaterCreate.fromJson(Map<String, Object?> json) => _$SyncWaterCreateFromJson(json);
  
  @JsonKey(name: 'amount_ml')
  final int amountMl;
  @JsonKey(name: 'client_uuid')
  final String clientUuid;
  @JsonKey(name: 'consumed_at')
  final DateTime consumedAt;
  final String op;
  @JsonKey(name: 'op_id')
  final String opId;

  Map<String, Object?> toJson() => _$SyncWaterCreateToJson(this);
}
