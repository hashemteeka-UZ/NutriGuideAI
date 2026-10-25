import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_failure.dart';
import '../../../core/network/dio_provider.dart';

/// `DELETE /me` (#311). The caller wipes the phone only after it succeeds.
class AccountDeleter {
  AccountDeleter(this._dio);

  final Dio _dio;

  Future<void> delete() async {
    try {
      await _dio.delete<Object>('/api/v1/me');
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}

final accountDeleterProvider = Provider<AccountDeleter>((ref) {
  return AccountDeleter(ref.watch(dioProvider));
});
