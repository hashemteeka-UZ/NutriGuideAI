// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_item_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanItemLog _$PlanItemLogFromJson(Map<String, dynamic> json) => PlanItemLog(
  clientUuid: json['client_uuid'] as String,
  consumedAt: DateTime.parse(json['consumed_at'] as String),
  kind: json['kind'] as String,
  planItemId: (json['plan_item_id'] as num).toInt(),
  servingsConsumed: json['servings_consumed'] as num,
);

Map<String, dynamic> _$PlanItemLogToJson(PlanItemLog instance) =>
    <String, dynamic>{
      'client_uuid': instance.clientUuid,
      'consumed_at': instance.consumedAt.toIso8601String(),
      'kind': instance.kind,
      'plan_item_id': instance.planItemId,
      'servings_consumed': instance.servingsConsumed,
    };
