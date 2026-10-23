// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_consumption_correct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncConsumptionCorrect _$SyncConsumptionCorrectFromJson(
  Map<String, dynamic> json,
) => SyncConsumptionCorrect(
  logId: (json['log_id'] as num).toInt(),
  newClientUuid: json['new_client_uuid'] as String,
  op: json['op'] as String,
  opId: json['op_id'] as String,
  consumedAt: json['consumed_at'] == null
      ? null
      : DateTime.parse(json['consumed_at'] as String),
  gramsConsumed: json['grams_consumed'] as num?,
  servingsConsumed: json['servings_consumed'] as num?,
  slot: json['slot'] == null ? null : MealSlot.fromJson(json['slot'] as String),
);

Map<String, dynamic> _$SyncConsumptionCorrectToJson(
  SyncConsumptionCorrect instance,
) => <String, dynamic>{
  'consumed_at': instance.consumedAt?.toIso8601String(),
  'grams_consumed': instance.gramsConsumed,
  'log_id': instance.logId,
  'new_client_uuid': instance.newClientUuid,
  'op': instance.op,
  'op_id': instance.opId,
  'servings_consumed': instance.servingsConsumed,
  'slot': instance.slot?.toJson(),
};
