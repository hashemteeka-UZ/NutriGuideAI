// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanStats _$PlanStatsFromJson(Map<String, dynamic> json) => PlanStats(
  candidateMeals: (json['candidate_meals'] as num).toInt(),
  kcalRelaxed: json['kcal_relaxed'] as bool,
  solveSeconds: json['solve_seconds'] as num,
  solverStatus: json['solver_status'] as String,
);

Map<String, dynamic> _$PlanStatsToJson(PlanStats instance) => <String, dynamic>{
  'candidate_meals': instance.candidateMeals,
  'kcal_relaxed': instance.kcalRelaxed,
  'solve_seconds': instance.solveSeconds,
  'solver_status': instance.solverStatus,
};
