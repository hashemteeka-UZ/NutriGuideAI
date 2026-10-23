// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'plan_target_out.g.dart';

@JsonSerializable()
class PlanTargetOut {
  const PlanTargetOut({
    required this.carbG,
    required this.fatG,
    required this.fiberG,
    required this.kcal,
    required this.proteinG,
  });
  
  factory PlanTargetOut.fromJson(Map<String, Object?> json) => _$PlanTargetOutFromJson(json);
  
  @JsonKey(name: 'carb_g')
  final num carbG;
  @JsonKey(name: 'fat_g')
  final num fatG;
  @JsonKey(name: 'fiber_g')
  final int fiberG;
  final int kcal;
  @JsonKey(name: 'protein_g')
  final num proteinG;

  Map<String, Object?> toJson() => _$PlanTargetOutToJson(this);
}
