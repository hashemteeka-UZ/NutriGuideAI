// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'interaction_out_status.dart';

part 'interaction_out.g.dart';

@JsonSerializable()
class InteractionOut {
  const InteractionOut({
    required this.interactionId,
    required this.status,
  });
  
  factory InteractionOut.fromJson(Map<String, Object?> json) => _$InteractionOutFromJson(json);
  
  @JsonKey(name: 'interaction_id')
  final int interactionId;
  final InteractionOutStatus status;

  Map<String, Object?> toJson() => _$InteractionOutToJson(this);
}
