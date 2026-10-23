// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/reference.dart';

part 'reference_client.g.dart';

@RestApi()
abstract class ReferenceClient {
  factory ReferenceClient(Dio dio, {String? baseUrl}) = _ReferenceClient;

  /// Get Reference.
  ///
  /// Conditions, allergens, cuisines, and the closed lists for sex, activity, goal, and slot. Names follow Accept-Language (ar default, en). DIABETES_INSULIN is included with is_supported false. The response sets Cache-Control: public, max-age=3600. dataset_version is the catalog version in DATASET_MANIFEST.yaml when the active meals' batch ids are exactly that file's meal batches. A missing or unreadable manifest, or a different set of batches, returns "unknown" and logs a warning; the request still succeeds.
  /// Error codes:.
  @GET('/api/v1/reference')
  Future<Reference> getReference();
}
