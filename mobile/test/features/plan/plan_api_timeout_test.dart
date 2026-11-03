import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/plan/data/plan_api.dart';
import 'package:nutriguide/features/plan/domain/plan.dart';

void main() {
  const defaultTimeout = Duration(seconds: 30);

  Dio dioWith(_Capture capture) {
    return Dio(
      BaseOptions(baseUrl: 'https://api.test', receiveTimeout: defaultTimeout),
    )..httpClientAdapter = capture;
  }

  test('a day build waits longer than the default receive timeout', () async {
    final capture = _Capture();
    final api = PlanApi(dioWith(capture));

    await expectLater(
      api.createDay(DateTime(2026, 11, 3)),
      throwsA(isA<PlanRequestException>()),
    );

    expect(capture.seen.single.path, '/api/v1/plans/days');
    expect(capture.seen.single.receiveTimeout, planDayReceiveTimeout);
    expect(
      planDayReceiveTimeout,
      greaterThanOrEqualTo(const Duration(seconds: 90)),
    );
  });

  test('other plan calls keep the default receive timeout', () async {
    final capture = _Capture();
    final api = PlanApi(dioWith(capture));

    await expectLater(
      api.shopping(from: DateTime(2026, 11, 3), to: DateTime(2026, 11, 9)),
      throwsA(isA<PlanRequestException>()),
    );

    expect(capture.seen.single.receiveTimeout, defaultTimeout);
  });
}

/// Records each request and answers with a planner problem.
class _Capture implements HttpClientAdapter {
  final List<RequestOptions> seen = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{
        'type': 'about:blank',
        'title': 'Planner timeout',
        'status': 503,
        'code': 'PLANNER_TIMEOUT',
      }),
      503,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/problem+json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
