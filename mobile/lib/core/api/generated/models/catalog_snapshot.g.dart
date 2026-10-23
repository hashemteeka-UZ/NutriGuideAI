// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogSnapshot _$CatalogSnapshotFromJson(Map<String, dynamic> json) =>
    CatalogSnapshot(
      datasetVersion: json['dataset_version'] as String,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      meals: (json['meals'] as List<dynamic>)
          .map((e) => SnapshotMeal.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CatalogSnapshotToJson(CatalogSnapshot instance) =>
    <String, dynamic>{
      'dataset_version': instance.datasetVersion,
      'generated_at': instance.generatedAt.toIso8601String(),
      'meals': instance.meals.map((e) => e.toJson()).toList(),
    };
