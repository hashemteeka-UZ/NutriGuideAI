import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/network/debug_request_log.dart';

void main() {
  test('a login log line contains no body and no header', () async {
    final logs = <String>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      logs.add(message ?? '');
    };
    addTearDown(() {
      debugPrint = previous;
    });

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
    dio.interceptors.add(const DebugRequestLogInterceptor());
    dio.httpClientAdapter = _OkAdapter();
    const email = 'ada@example.com';
    const password = 's3cret-password';
    const token = 'super-secret-token';

    await dio.post<dynamic>(
      '/api/v1/auth/login',
      data: <String, Object?>{'email': email, 'password': password},
      options: Options(
        headers: <String, Object?>{'Authorization': 'Bearer $token'},
      ),
    );

    expect(logs, hasLength(1));
    final line = logs.single;
    expect(line, matches(RegExp(r'^POST /api/v1/auth/login 200 \d+ms$')));
    expect(line.contains(email), isFalse);
    expect(line.contains(password), isFalse);
    expect(line.contains(token), isFalse);
    expect(line.contains('Authorization'), isFalse);
    expect(line.contains('Bearer'), isFalse);
    expect(line.contains('password'), isFalse);
  });
}

class _OkAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{}',
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
