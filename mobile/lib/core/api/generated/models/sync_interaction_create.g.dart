// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_interaction_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncInteractionCreate _$SyncInteractionCreateFromJson(
  Map<String, dynamic> json,
) => SyncInteractionCreate(
  clientUuid: json['client_uuid'] as String,
  eventType: SyncInteractionCreateEventType.fromJson(
    json['event_type'] as String,
  ),
  mealId: (json['meal_id'] as num).toInt(),
  op: json['op'] as String,
  opId: json['op_id'] as String,
  planItemId: (json['plan_item_id'] as num?)?.toInt(),
  screen: json['screen'] as String?,
  value: (json['value'] as num?)?.toInt(),
);

Map<String, dynamic> _$SyncInteractionCreateToJson(
  SyncInteractionCreate instance,
) => <String, dynamic>{
  'client_uuid': instance.clientUuid,
  'event_type': instance.eventType.toJson(),
  'meal_id': instance.mealId,
  'op': instance.op,
  'op_id': instance.opId,
  'plan_item_id': instance.planItemId,
  'screen': instance.screen,
  'value': instance.value,
};
