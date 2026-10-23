// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'health_response.g.dart';

@JsonSerializable()
class HealthResponse {
  const HealthResponse({
    required this.apiVersion,
    required this.database,
    required this.datasetVersion,
    required this.defaultPlanner,
    required this.status,
  });
  
  factory HealthResponse.fromJson(Map<String, Object?> json) => _$HealthResponseFromJson(json);
  
  @JsonKey(name: 'api_version')
  final String apiVersion;
  final String database;
  @JsonKey(name: 'dataset_version')
  final String? datasetVersion;
  @JsonKey(name: 'default_planner')
  final String defaultPlanner;
  final String status;

  Map<String, Object?> toJson() => _$HealthResponseToJson(this);
}
