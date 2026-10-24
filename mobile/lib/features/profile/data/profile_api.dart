import 'package:dio/dio.dart';

import '../../../core/api/generated/models/profile_state.dart';
import '../../../core/api/generated/models/targets_view.dart';
import '../../../core/network/app_failure.dart';

abstract interface class ProfileApi {
  Future<ProfileState> putProfile(Map<String, Object?> body);

  Future<TargetsView> getTargets();
}

final class DioProfileApi implements ProfileApi {
  DioProfileApi(this._dio);

  final Dio _dio;

  @override
  Future<ProfileState> putProfile(Map<String, Object?> body) async {
    final response = await _dio.put<Object>('/api/v1/me/profile', data: body);
    return ProfileState.fromJson(
      _objectMap(response.data, response.statusCode),
    );
  }

  @override
  Future<TargetsView> getTargets() async {
    final response = await _dio.get<Object>('/api/v1/me/targets');
    return TargetsView.fromJson(_objectMap(response.data, response.statusCode));
  }
}

Map<String, Object?> _objectMap(Object? data, int? status) {
  if (data is Map) {
    return data.map(
      (dynamic key, dynamic value) => MapEntry('$key', value as Object?),
    );
  }
  throw UnexpectedResponse(status);
}
