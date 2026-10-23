// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_op_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncOpResult _$SyncOpResultFromJson(Map<String, dynamic> json) => SyncOpResult(
  opId: json['op_id'] as String,
  status: SyncOpResultStatus.fromJson(json['status'] as String),
  code: json['code'] as String?,
  entityId: (json['entity_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$SyncOpResultToJson(SyncOpResult instance) =>
    <String, dynamic>{
      'code': instance.code,
      'entity_id': instance.entityId,
      'op_id': instance.opId,
      'status': instance.status.toJson(),
    };
