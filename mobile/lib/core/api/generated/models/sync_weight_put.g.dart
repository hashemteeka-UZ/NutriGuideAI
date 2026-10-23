// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_weight_put.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncWeightPut _$SyncWeightPutFromJson(Map<String, dynamic> json) =>
    SyncWeightPut(
      measuredOn: DateTime.parse(json['measured_on'] as String),
      op: json['op'] as String,
      opId: json['op_id'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      weightKg: json['weight_kg'] as num,
    );

Map<String, dynamic> _$SyncWeightPutToJson(SyncWeightPut instance) =>
    <String, dynamic>{
      'measured_on': instance.measuredOn.toIso8601String(),
      'op': instance.op,
      'op_id': instance.opId,
      'updated_at': instance.updatedAt.toIso8601String(),
      'weight_kg': instance.weightKg,
    };
