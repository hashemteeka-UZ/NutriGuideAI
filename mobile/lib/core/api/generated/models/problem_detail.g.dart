// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProblemDetail _$ProblemDetailFromJson(Map<String, dynamic> json) =>
    ProblemDetail(
      code: json['code'] as String,
      status: (json['status'] as num).toInt(),
      title: json['title'] as String,
      type: json['type'] as String? ?? 'about:blank',
      detail: json['detail'] as String?,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => ValidationIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
      reasons: (json['reasons'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      requestId: json['request_id'] as String?,
    );

Map<String, dynamic> _$ProblemDetailToJson(ProblemDetail instance) =>
    <String, dynamic>{
      'code': instance.code,
      'detail': instance.detail,
      'errors': instance.errors?.map((e) => e.toJson()).toList(),
      'reasons': instance.reasons,
      'request_id': instance.requestId,
      'status': instance.status,
      'title': instance.title,
      'type': instance.type,
    };
