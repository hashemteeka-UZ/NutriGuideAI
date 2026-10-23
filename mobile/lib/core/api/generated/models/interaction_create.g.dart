// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interaction_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InteractionCreate _$InteractionCreateFromJson(Map<String, dynamic> json) =>
    InteractionCreate(
      clientUuid: json['client_uuid'] as String,
      eventType: InteractionCreateEventType.fromJson(
        json['event_type'] as String,
      ),
      mealId: (json['meal_id'] as num).toInt(),
      planItemId: (json['plan_item_id'] as num?)?.toInt(),
      screen: json['screen'] as String?,
      value: (json['value'] as num?)?.toInt(),
    );

Map<String, dynamic> _$InteractionCreateToJson(InteractionCreate instance) =>
    <String, dynamic>{
      'client_uuid': instance.clientUuid,
      'event_type': instance.eventType.toJson(),
      'meal_id': instance.mealId,
      'plan_item_id': instance.planItemId,
      'screen': instance.screen,
      'value': instance.value,
    };
