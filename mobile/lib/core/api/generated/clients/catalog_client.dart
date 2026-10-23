// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/catalog_snapshot.dart';

part 'catalog_client.g.dart';

@RestApi()
abstract class CatalogClient {
  factory CatalogClient(Dio dio, {String? baseUrl}) = _CatalogClient;

  /// Get Catalog Snapshot.
  ///
  /// Every active meal, without a personal stance, ordered by meal_id. dataset_version is the catalog version. ETag is a strong tag: the SHA-256 of the canonical JSON of the snapshot without generated_at (sorted keys, no spaces), plus the language. If-None-Match equal to that tag, a comma-separated list containing it, or * returns 304 with an empty body and the ETag. Otherwise 200 with ETag and Cache-Control: private, no-cache. Vary is Accept-Language, Authorization, and Accept-Encoding when the body is large enough to gzip. A response of at least 1024 bytes is gzip-encoded when the client accepts gzip.
  /// Error codes: UNAUTHORIZED.
  @GET('/api/v1/catalog/snapshot')
  Future<CatalogSnapshot> getCatalogSnapshot({
    @Header('If-None-Match') String? ifNoneMatch,
  });
}
