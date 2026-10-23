// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_target_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanTargetOut _$PlanTargetOutFromJson(Map<String, dynamic> json) =>
    PlanTargetOut(
      carbG: json['carb_g'] as num,
      fatG: json['fat_g'] as num,
      fiberG: (json['fiber_g'] as num).toInt(),
      kcal: (json['kcal'] as num).toInt(),
      proteinG: json['protein_g'] as num,
    );

Map<String, dynamic> _$PlanTargetOutToJson(PlanTargetOut instance) =>
    <String, dynamic>{
      'carb_g': instance.carbG,
      'fat_g': instance.fatG,
      'fiber_g': instance.fiberG,
      'kcal': instance.kcal,
      'protein_g': instance.proteinG,
    };
