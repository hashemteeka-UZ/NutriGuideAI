// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sync_interaction_create_event_type.dart';

part 'sync_interaction_create.g.dart';

@JsonSerializable()
class SyncInteractionCreate {
  const SyncInteractionCreate({
    required this.clientUuid,
    required this.eventType,
    required this.mealId,
    required this.op,
    required this.opId,
    this.planItemId,
    this.screen,
    this.value,
  });
  
  factory SyncInteractionCreate.fromJson(Map<String, Object?> json) => _$SyncInteractionCreateFromJson(json);
  
  @JsonKey(name: 'client_uuid')
  final String clientUuid;
  @JsonKey(name: 'event_type')
  final SyncInteractionCreateEventType eventType;
  @JsonKey(name: 'meal_id')
  final int mealId;
  final String op;
  @JsonKey(name: 'op_id')
  final String opId;
  @JsonKey(name: 'plan_item_id')
  final int? planItemId;
  final String? screen;
  final int? value;

  Map<String, Object?> toJson() => _$SyncInteractionCreateToJson(this);
}
