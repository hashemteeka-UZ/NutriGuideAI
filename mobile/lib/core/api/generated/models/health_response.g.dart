// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthResponse _$HealthResponseFromJson(Map<String, dynamic> json) =>
    HealthResponse(
      apiVersion: json['api_version'] as String,
      database: json['database'] as String,
      datasetVersion: json['dataset_version'] as String?,
      defaultPlanner: json['default_planner'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$HealthResponseToJson(HealthResponse instance) =>
    <String, dynamic>{
      'api_version': instance.apiVersion,
      'database': instance.database,
      'dataset_version': instance.datasetVersion,
      'default_planner': instance.defaultPlanner,
      'status': instance.status,
    };
