// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'interaction_create_event_type.dart';

part 'interaction_create.g.dart';

@JsonSerializable()
class InteractionCreate {
  const InteractionCreate({
    required this.clientUuid,
    required this.eventType,
    required this.mealId,
    this.planItemId,
    this.screen,
    this.value,
  });
  
  factory InteractionCreate.fromJson(Map<String, Object?> json) => _$InteractionCreateFromJson(json);
  
  @JsonKey(name: 'client_uuid')
  final String clientUuid;
  @JsonKey(name: 'event_type')
  final InteractionCreateEventType eventType;
  @JsonKey(name: 'meal_id')
  final int mealId;
  @JsonKey(name: 'plan_item_id')
  final int? planItemId;
  final String? screen;
  final int? value;

  Map<String, Object?> toJson() => _$InteractionCreateToJson(this);
}
