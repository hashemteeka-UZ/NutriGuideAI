// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IngredientPage _$IngredientPageFromJson(Map<String, dynamic> json) =>
    IngredientPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => IngredientHit.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$IngredientPageToJson(IngredientPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
