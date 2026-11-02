// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'day_adherence_out.dart';

part 'adherence_range_out.g.dart';

@JsonSerializable()
class AdherenceRangeOut {
  const AdherenceRangeOut({
    required this.days,
    required this.streak,
  });
  
  factory AdherenceRangeOut.fromJson(Map<String, Object?> json) => _$AdherenceRangeOutFromJson(json);
  
  final List<DayAdherenceOut> days;
  final int streak;

  Map<String, Object?> toJson() => _$AdherenceRangeOutToJson(this);
}
