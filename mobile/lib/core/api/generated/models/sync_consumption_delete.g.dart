// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_consumption_delete.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncConsumptionDelete _$SyncConsumptionDeleteFromJson(
  Map<String, dynamic> json,
) => SyncConsumptionDelete(
  logId: (json['log_id'] as num).toInt(),
  op: json['op'] as String,
  opId: json['op_id'] as String,
);

Map<String, dynamic> _$SyncConsumptionDeleteToJson(
  SyncConsumptionDelete instance,
) => <String, dynamic>{
  'log_id': instance.logId,
  'op': instance.op,
  'op_id': instance.opId,
};
