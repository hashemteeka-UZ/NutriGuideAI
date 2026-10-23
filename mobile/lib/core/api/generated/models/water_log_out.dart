// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'water_log_out.g.dart';

@JsonSerializable()
class WaterLogOut {
  const WaterLogOut({
    required this.amountMl,
    required this.consumedAt,
    required this.logId,
  });
  
  factory WaterLogOut.fromJson(Map<String, Object?> json) => _$WaterLogOutFromJson(json);
  
  @JsonKey(name: 'amount_ml')
  final int amountMl;
  @JsonKey(name: 'consumed_at')
  final DateTime consumedAt;
  @JsonKey(name: 'log_id')
  final int logId;

  Map<String, Object?> toJson() => _$WaterLogOutToJson(this);
}
