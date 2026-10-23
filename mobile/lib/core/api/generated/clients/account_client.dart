// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/account.dart';

part 'account_client.g.dart';

@RestApi()
abstract class AccountClient {
  factory AccountClient(Dio dio, {String? baseUrl}) = _AccountClient;

  /// Delete Me.
  ///
  /// Delete the account and every row that belongs to it.
  /// Error codes: UNAUTHORIZED.
  @DELETE('/api/v1/me')
  Future<void> deleteMe();

  /// Get Me.
  ///
  /// Account identity. has_profile is false until the first successful PUT /me/profile.
  /// Error codes: UNAUTHORIZED.
  @GET('/api/v1/me')
  Future<Account> getMe();
}
