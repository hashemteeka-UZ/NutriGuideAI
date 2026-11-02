// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'code_name.g.dart';

@JsonSerializable()
class CodeName {
  const CodeName({
    required this.code,
    required this.name,
  });
  
  factory CodeName.fromJson(Map<String, Object?> json) => _$CodeNameFromJson(json);
  
  final String code;
  final String name;

  Map<String, Object?> toJson() => _$CodeNameToJson(this);
}
