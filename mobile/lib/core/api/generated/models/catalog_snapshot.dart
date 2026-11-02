// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'snapshot_meal.dart';

part 'catalog_snapshot.g.dart';

@JsonSerializable()
class CatalogSnapshot {
  const CatalogSnapshot({
    required this.datasetVersion,
    required this.generatedAt,
    required this.meals,
  });
  
  factory CatalogSnapshot.fromJson(Map<String, Object?> json) => _$CatalogSnapshotFromJson(json);
  
  @JsonKey(name: 'dataset_version')
  final String datasetVersion;
  @JsonKey(name: 'generated_at')
  final DateTime generatedAt;
  final List<SnapshotMeal> meals;

  Map<String, Object?> toJson() => _$CatalogSnapshotToJson(this);
}
