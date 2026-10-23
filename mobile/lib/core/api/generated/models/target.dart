// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'target_reason.dart';

part 'target.g.dart';

@JsonSerializable()
class Target {
  const Target({
    required this.basedOnWeightKg,
    required this.bmrKcal,
    required this.carbG,
    required this.fatG,
    required this.fiberG,
    required this.formulaVersion,
    required this.kcal,
    required this.proteinG,
    required this.reason,
    required this.targetId,
    required this.tdeeKcal,
    required this.validFrom,
    required this.wasFloorApplied,
  });
  
  factory Target.fromJson(Map<String, Object?> json) => _$TargetFromJson(json);
  
  @JsonKey(name: 'based_on_weight_kg')
  final num basedOnWeightKg;
  @JsonKey(name: 'bmr_kcal')
  final num bmrKcal;
  @JsonKey(name: 'carb_g')
  final num carbG;
  @JsonKey(name: 'fat_g')
  final num fatG;
  @JsonKey(name: 'fiber_g')
  final int fiberG;
  @JsonKey(name: 'formula_version')
  final String formulaVersion;
  final int kcal;
  @JsonKey(name: 'protein_g')
  final num proteinG;
  final TargetReason reason;
  @JsonKey(name: 'target_id')
  final int targetId;
  @JsonKey(name: 'tdee_kcal')
  final num tdeeKcal;
  @JsonKey(name: 'valid_from')
  final DateTime validFrom;
  @JsonKey(name: 'was_floor_applied')
  final bool wasFloorApplied;

  Map<String, Object?> toJson() => _$TargetToJson(this);
}
