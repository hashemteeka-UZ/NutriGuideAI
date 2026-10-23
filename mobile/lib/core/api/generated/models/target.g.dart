// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Target _$TargetFromJson(Map<String, dynamic> json) => Target(
  basedOnWeightKg: json['based_on_weight_kg'] as num,
  bmrKcal: json['bmr_kcal'] as num,
  carbG: json['carb_g'] as num,
  fatG: json['fat_g'] as num,
  fiberG: (json['fiber_g'] as num).toInt(),
  formulaVersion: json['formula_version'] as String,
  kcal: (json['kcal'] as num).toInt(),
  proteinG: json['protein_g'] as num,
  reason: TargetReason.fromJson(json['reason'] as String),
  targetId: (json['target_id'] as num).toInt(),
  tdeeKcal: json['tdee_kcal'] as num,
  validFrom: DateTime.parse(json['valid_from'] as String),
  wasFloorApplied: json['was_floor_applied'] as bool,
);

Map<String, dynamic> _$TargetToJson(Target instance) => <String, dynamic>{
  'based_on_weight_kg': instance.basedOnWeightKg,
  'bmr_kcal': instance.bmrKcal,
  'carb_g': instance.carbG,
  'fat_g': instance.fatG,
  'fiber_g': instance.fiberG,
  'formula_version': instance.formulaVersion,
  'kcal': instance.kcal,
  'protein_g': instance.proteinG,
  'reason': instance.reason.toJson(),
  'target_id': instance.targetId,
  'tdee_kcal': instance.tdeeKcal,
  'valid_from': instance.validFrom.toIso8601String(),
  'was_floor_applied': instance.wasFloorApplied,
};
