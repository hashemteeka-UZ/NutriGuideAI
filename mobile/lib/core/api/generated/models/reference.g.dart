// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reference _$ReferenceFromJson(Map<String, dynamic> json) => Reference(
  activityLevels: (json['activity_levels'] as List<dynamic>)
      .map((e) => ActivityLevel.fromJson(e as String))
      .toList(),
  allergens: (json['allergens'] as List<dynamic>)
      .map((e) => CodeName.fromJson(e as Map<String, dynamic>))
      .toList(),
  cuisines: (json['cuisines'] as List<dynamic>)
      .map((e) => CodeName.fromJson(e as Map<String, dynamic>))
      .toList(),
  datasetVersion: json['dataset_version'] as String,
  goalTypes: (json['goal_types'] as List<dynamic>)
      .map((e) => GoalType.fromJson(e as String))
      .toList(),
  healthConditions: (json['health_conditions'] as List<dynamic>)
      .map((e) => ConditionRef.fromJson(e as Map<String, dynamic>))
      .toList(),
  sexes: (json['sexes'] as List<dynamic>)
      .map((e) => Sex.fromJson(e as String))
      .toList(),
  slots: (json['slots'] as List<dynamic>)
      .map((e) => MealSlot.fromJson(e as String))
      .toList(),
);

Map<String, dynamic> _$ReferenceToJson(Reference instance) => <String, dynamic>{
  'activity_levels': instance.activityLevels.map((e) => e.toJson()).toList(),
  'allergens': instance.allergens.map((e) => e.toJson()).toList(),
  'cuisines': instance.cuisines.map((e) => e.toJson()).toList(),
  'dataset_version': instance.datasetVersion,
  'goal_types': instance.goalTypes.map((e) => e.toJson()).toList(),
  'health_conditions': instance.healthConditions
      .map((e) => e.toJson())
      .toList(),
  'sexes': instance.sexes.map((e) => e.toJson()).toList(),
  'slots': instance.slots.map((e) => e.toJson()).toList(),
};
