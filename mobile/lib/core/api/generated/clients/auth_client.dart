// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/login_request.dart';
import '../models/refresh_request.dart';
import '../models/register_request.dart';
import '../models/token_pair.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// Login.
  ///
  /// Exchange an email and password for a new token pair.
  /// Error codes: INVALID_CREDENTIALS, RATE_LIMITED.
  @POST('/api/v1/auth/login')
  Future<TokenPair> login({
    @Body() required LoginRequest body,
  });

  /// Logout.
  ///
  /// Revoke the refresh token. No content on success.
  /// Error codes: VALIDATION_ERROR.
  @POST('/api/v1/auth/logout')
  Future<void> logout({
    @Body() required RefreshRequest body,
  });

  /// Refresh Session.
  ///
  /// Rotate a refresh token. TOKEN_REUSED means the token was already used; the app logs out.
  /// Error codes: TOKEN_INVALID, TOKEN_REUSED, RATE_LIMITED.
  @POST('/api/v1/auth/refresh')
  Future<TokenPair> refreshSession({
    @Body() required RefreshRequest body,
  });

  /// Register.
  ///
  /// Create an account and return an access token and a refresh token.
  /// Error codes: EMAIL_TAKEN, VALIDATION_ERROR, RATE_LIMITED.
  @POST('/api/v1/auth/register')
  Future<TokenPair> register({
    @Body() required RegisterRequest body,
  });
}
