// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingList _$ShoppingListFromJson(Map<String, dynamic> json) => ShoppingList(
  dateFrom: DateTime.parse(json['date_from'] as String),
  dateTo: DateTime.parse(json['date_to'] as String),
  items: (json['items'] as List<dynamic>)
      .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ShoppingListToJson(ShoppingList instance) =>
    <String, dynamic>{
      'date_from': instance.dateFrom.toIso8601String(),
      'date_to': instance.dateTo.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
