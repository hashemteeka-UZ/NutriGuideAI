// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/weight_out.dart';
import '../models/weight_point.dart';
import '../models/weight_update.dart';

part 'weights_client.g.dart';

@RestApi()
abstract class WeightsClient {
  factory WeightsClient(Dio dio, {String? baseUrl}) = _WeightsClient;

  /// List Weights.
  ///
  /// Weights in the inclusive range, ordered by date. Maximum 92 days.
  /// Error codes: UNAUTHORIZED, VALIDATION_ERROR.
  @GET('/api/v1/weights')
  Future<List<WeightPoint>> listWeights({
    @Query('from') required DateTime from,
    @Query('to') required DateTime to,
  });

  /// Put Weight.
  ///
  /// Create or replace the weight of that local date. STALE_IGNORED keeps the stored row when updated_at is older. A new target created by the weight is stored in the same transaction.
  /// Error codes: UNAUTHORIZED, PROFILE_NOT_FOUND, CLOCK_SKEW, VALIDATION_ERROR.
  @PUT('/api/v1/weights/{measured_on}')
  Future<WeightOut> putWeight({
    @Path('measured_on') required DateTime measuredOn,
    @Body() required WeightUpdate body,
  });
}
