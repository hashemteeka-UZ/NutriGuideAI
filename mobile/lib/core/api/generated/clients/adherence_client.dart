// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/adherence_range_out.dart';

part 'adherence_client.g.dart';

@RestApi()
abstract class AdherenceClient {
  factory AdherenceClient(Dio dio, {String? baseUrl}) = _AdherenceClient;

  /// Get Adherence.
  ///
  /// One row per day in the inclusive range, plus the streak of consecutive ACHIEVED days ending on the last day. Maximum 92 days; a longer range is VALIDATION_ERROR.
  /// Error codes: UNAUTHORIZED, PROFILE_NOT_FOUND, VALIDATION_ERROR.
  @GET('/api/v1/adherence')
  Future<AdherenceRangeOut> getAdherence({
    @Query('from') required DateTime from,
    @Query('to') required DateTime to,
  });
}
