// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'water_log_create.g.dart';

@JsonSerializable()
class WaterLogCreate {
  const WaterLogCreate({
    required this.amountMl,
    required this.clientUuid,
    required this.consumedAt,
  });
  
  factory WaterLogCreate.fromJson(Map<String, Object?> json) => _$WaterLogCreateFromJson(json);
  
  @JsonKey(name: 'amount_ml')
  final int amountMl;
  @JsonKey(name: 'client_uuid')
  final String clientUuid;
  @JsonKey(name: 'consumed_at')
  final DateTime consumedAt;

  Map<String, Object?> toJson() => _$WaterLogCreateToJson(this);
}
