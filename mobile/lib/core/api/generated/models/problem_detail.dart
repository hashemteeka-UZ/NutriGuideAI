// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'validation_issue.dart';

part 'problem_detail.g.dart';

@JsonSerializable()
class ProblemDetail {
  const ProblemDetail({
    required this.code,
    required this.status,
    required this.title,
    this.type = 'about:blank',
    this.detail,
    this.errors,
    this.reasons,
    this.requestId,
  });
  
  factory ProblemDetail.fromJson(Map<String, Object?> json) => _$ProblemDetailFromJson(json);
  
  final String code;
  final String? detail;
  final List<ValidationIssue>? errors;
  final List<String>? reasons;
  @JsonKey(name: 'request_id')
  final String? requestId;
  final int status;
  final String title;
  final String type;

  Map<String, Object?> toJson() => _$ProblemDetailToJson(this);
}
