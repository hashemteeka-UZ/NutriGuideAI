// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sync_op_result_status.dart';

part 'sync_op_result.g.dart';

@JsonSerializable()
class SyncOpResult {
  const SyncOpResult({
    required this.opId,
    required this.status,
    this.code,
    this.entityId,
  });
  
  factory SyncOpResult.fromJson(Map<String, Object?> json) => _$SyncOpResultFromJson(json);
  
  final String? code;
  @JsonKey(name: 'entity_id')
  final int? entityId;
  @JsonKey(name: 'op_id')
  final String opId;
  final SyncOpResultStatus status;

  Map<String, Object?> toJson() => _$SyncOpResultToJson(this);
}
