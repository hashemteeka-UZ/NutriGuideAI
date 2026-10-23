// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'validation_issue.g.dart';

@JsonSerializable()
class ValidationIssue {
  const ValidationIssue({
    required this.loc,
    required this.msg,
    required this.type,
  });
  
  factory ValidationIssue.fromJson(Map<String, Object?> json) => _$ValidationIssueFromJson(json);
  
  final List<dynamic> loc;
  final String msg;
  final String type;

  Map<String, Object?> toJson() => _$ValidationIssueToJson(this);
}
