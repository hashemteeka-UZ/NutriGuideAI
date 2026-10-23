// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealPage _$MealPageFromJson(Map<String, dynamic> json) => MealPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => MealSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$MealPageToJson(MealPage instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
};
