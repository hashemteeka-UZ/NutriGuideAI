// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meal_slot.dart';
import 'meal_summary.dart';

part 'plan_item_out.g.dart';

@JsonSerializable()
class PlanItemOut {
  const PlanItemOut({
    required this.carbG,
    required this.fatG,
    required this.grams,
    required this.kcal,
    required this.logged,
    required this.meal,
    required this.planItemId,
    required this.proteinG,
    required this.reasonCodes,
    required this.servingsMultiplier,
    required this.slot,
    required this.wasSwapped,
  });
  
  factory PlanItemOut.fromJson(Map<String, Object?> json) => _$PlanItemOutFromJson(json);
  
  @JsonKey(name: 'carb_g')
  final num carbG;
  @JsonKey(name: 'fat_g')
  final num fatG;
  final num grams;
  final num kcal;
  final bool logged;
  final MealSummary meal;
  @JsonKey(name: 'plan_item_id')
  final int planItemId;
  @JsonKey(name: 'protein_g')
  final num proteinG;
  @JsonKey(name: 'reason_codes')
  final List<String> reasonCodes;
  @JsonKey(name: 'servings_multiplier')
  final num servingsMultiplier;
  final MealSlot slot;
  @JsonKey(name: 'was_swapped')
  final bool wasSwapped;

  Map<String, Object?> toJson() => _$PlanItemOutToJson(this);
}
