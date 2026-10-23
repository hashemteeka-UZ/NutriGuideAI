// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_water_delete.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncWaterDelete _$SyncWaterDeleteFromJson(Map<String, dynamic> json) =>
    SyncWaterDelete(
      logId: (json['log_id'] as num).toInt(),
      op: json['op'] as String,
      opId: json['op_id'] as String,
    );

Map<String, dynamic> _$SyncWaterDeleteToJson(SyncWaterDelete instance) =>
    <String, dynamic>{
      'log_id': instance.logId,
      'op': instance.op,
      'op_id': instance.opId,
    };
