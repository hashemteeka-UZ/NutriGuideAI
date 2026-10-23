// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/water_day.dart';
import '../models/water_log_create.dart';
import '../models/water_log_result.dart';

part 'water_client.g.dart';

@RestApi()
abstract class WaterClient {
  factory WaterClient(Dio dio, {String? baseUrl}) = _WaterClient;

  /// Get Water Day.
  ///
  /// Total, goal, and active logs for one local date.
  /// Error codes: UNAUTHORIZED, PROFILE_NOT_FOUND, VALIDATION_ERROR.
  @GET('/api/v1/water')
  Future<WaterDay> getWaterDay({
    @Query('date') required DateTime date,
  });

  /// Create Water Log.
  ///
  /// Add a glass. consumed_at may be at most 5 minutes after the server clock (CLOCK_SKEW) and its local date may not be more than 30 days before the user's local today (VALIDATION_ERROR). 201 when created, 200 when the same client_uuid and content were already stored.
  /// Error codes: UNAUTHORIZED, PROFILE_NOT_FOUND, CLIENT_UUID_CONFLICT, CLOCK_SKEW, VALIDATION_ERROR.
  @POST('/api/v1/water-logs')
  Future<WaterLogResult> createWaterLog({
    @Body() required WaterLogCreate body,
  });

  /// Delete Water Log.
  ///
  /// Remove a water log.
  /// Error codes: UNAUTHORIZED, LOG_NOT_FOUND.
  @DELETE('/api/v1/water-logs/{log_id}')
  Future<void> deleteWaterLog({
    @Path('log_id') required int logId,
  });
}
