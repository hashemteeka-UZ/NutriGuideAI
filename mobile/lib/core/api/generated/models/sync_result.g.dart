// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncResult _$SyncResultFromJson(Map<String, dynamic> json) => SyncResult(
  results: (json['results'] as List<dynamic>)
      .map((e) => SyncOpResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  serverTime: DateTime.parse(json['server_time'] as String),
);

Map<String, dynamic> _$SyncResultToJson(SyncResult instance) =>
    <String, dynamic>{
      'results': instance.results.map((e) => e.toJson()).toList(),
      'server_time': instance.serverTime.toIso8601String(),
    };
