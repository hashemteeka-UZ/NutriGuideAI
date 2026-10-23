// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_water_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncWaterCreate _$SyncWaterCreateFromJson(Map<String, dynamic> json) =>
    SyncWaterCreate(
      amountMl: (json['amount_ml'] as num).toInt(),
      clientUuid: json['client_uuid'] as String,
      consumedAt: DateTime.parse(json['consumed_at'] as String),
      op: json['op'] as String,
      opId: json['op_id'] as String,
    );

Map<String, dynamic> _$SyncWaterCreateToJson(SyncWaterCreate instance) =>
    <String, dynamic>{
      'amount_ml': instance.amountMl,
      'client_uuid': instance.clientUuid,
      'consumed_at': instance.consumedAt.toIso8601String(),
      'op': instance.op,
      'op_id': instance.opId,
    };
