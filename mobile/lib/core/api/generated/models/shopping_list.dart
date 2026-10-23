// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shopping_item.dart';

part 'shopping_list.g.dart';

@JsonSerializable()
class ShoppingList {
  const ShoppingList({
    required this.dateFrom,
    required this.dateTo,
    required this.items,
  });
  
  factory ShoppingList.fromJson(Map<String, Object?> json) => _$ShoppingListFromJson(json);
  
  @JsonKey(name: 'date_from')
  final DateTime dateFrom;
  @JsonKey(name: 'date_to')
  final DateTime dateTo;
  final List<ShoppingItem> items;

  Map<String, Object?> toJson() => _$ShoppingListToJson(this);
}
