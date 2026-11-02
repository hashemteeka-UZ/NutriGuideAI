// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'plan_stats.g.dart';

@JsonSerializable()
class PlanStats {
  const PlanStats({
    required this.candidateMeals,
    required this.kcalRelaxed,
    required this.solveSeconds,
    required this.solverStatus,
  });
  
  factory PlanStats.fromJson(Map<String, Object?> json) => _$PlanStatsFromJson(json);
  
  /// Distinct meals that passed Layer 1 for at least one position.
  @JsonKey(name: 'candidate_meals')
  final int candidateMeals;

  /// True when phase 2 dropped the daily energy band.
  @JsonKey(name: 'kcal_relaxed')
  final bool kcalRelaxed;

  /// Solver time in seconds, rounded to 3 decimal places.
  @JsonKey(name: 'solve_seconds')
  final num solveSeconds;

  /// CP-SAT status stored on the plan (OPTIMAL or FEASIBLE).
  @JsonKey(name: 'solver_status')
  final String solverStatus;

  Map<String, Object?> toJson() => _$PlanStatsToJson(this);
}
