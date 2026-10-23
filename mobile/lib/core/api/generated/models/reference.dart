// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'activity_level.dart';
import 'code_name.dart';
import 'condition_ref.dart';
import 'goal_type.dart';
import 'meal_slot.dart';
import 'sex.dart';

part 'reference.g.dart';

@JsonSerializable()
class Reference {
  const Reference({
    required this.activityLevels,
    required this.allergens,
    required this.cuisines,
    required this.datasetVersion,
    required this.goalTypes,
    required this.healthConditions,
    required this.sexes,
    required this.slots,
  });
  
  factory Reference.fromJson(Map<String, Object?> json) => _$ReferenceFromJson(json);
  
  @JsonKey(name: 'activity_levels')
  final List<ActivityLevel> activityLevels;
  final List<CodeName> allergens;
  final List<CodeName> cuisines;

  /// Active catalog dataset_version shared with GET /health, or "unknown" when active meals do not share exactly one version.
  @JsonKey(name: 'dataset_version')
  final String datasetVersion;
  @JsonKey(name: 'goal_types')
  final List<GoalType> goalTypes;
  @JsonKey(name: 'health_conditions')
  final List<ConditionRef> healthConditions;
  final List<Sex> sexes;
  final List<MealSlot> slots;

  Map<String, Object?> toJson() => _$ReferenceToJson(this);
}
