// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'plan_item_log.g.dart';

@JsonSerializable()
class PlanItemLog {
  const PlanItemLog({
    required this.clientUuid,
    required this.consumedAt,
    required this.kind,
    required this.planItemId,
    required this.servingsConsumed,
  });
  
  factory PlanItemLog.fromJson(Map<String, Object?> json) => _$PlanItemLogFromJson(json);
  
  @JsonKey(name: 'client_uuid')
  final String clientUuid;
  @JsonKey(name: 'consumed_at')
  final DateTime consumedAt;
  final String kind;
  @JsonKey(name: 'plan_item_id')
  final int planItemId;
  @JsonKey(name: 'servings_consumed')
  final num servingsConsumed;

  Map<String, Object?> toJson() => _$PlanItemLogToJson(this);
}
