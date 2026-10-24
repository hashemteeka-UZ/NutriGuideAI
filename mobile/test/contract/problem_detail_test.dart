import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/problem_detail.dart';
import 'package:nutriguide/core/network/app_failure.dart';

void main() {
  test('parses the ProblemDetail example', () {
    final decoded = jsonDecode(
      '{"type":"about:blank","title":"Validation error","status":422,'
      '"code":"VALIDATION_ERROR","request_id":"req-1","errors":['
      '{"loc":["body","password"],"msg":"field required","type":"missing"}]}',
    ) as Map<String, dynamic>;
    final model = ProblemDetail.fromJson(Map<String, Object?>.from(decoded));

    expect(model.type, 'about:blank');
    expect(model.title, 'Validation error');
    expect(model.status, 422);
    expect(model.code, 'VALIDATION_ERROR');
    expect(model.requestId, 'req-1');
    expect(model.errors, hasLength(1));
    expect(model.errors!.single.loc, <Object>['body', 'password']);
    expect(model.errors!.single.msg, 'field required');
    expect(model.errors!.single.type, 'missing');
  });

  test('mapResponse keeps errors and reasons', () {
    final failure = mapResponse(
      _response(
        statusCode: 422,
        data: <String, Object?>{
          'title': 'Validation error',
          'status': 422,
          'code': 'VALIDATION_ERROR',
          'errors': <Object?>[
            <String, Object?>{
              'loc': <Object>['body', 'email'],
              'msg': 'invalid',
              'type': 'value_error',
            },
            <String, Object?>{
              'loc': <Object>['items', 0, 'password'],
              'msg': 'short',
              'type': 'string_too_short',
            },
          ],
          'reasons': <Object?>['UNDER_18', 'PREGNANT'],
        },
      ),
    );

    final problem = failure as ApiProblem;
    expect(problem.errors, hasLength(2));
    expect(problem.errors.first.loc, <Object>['body', 'email']);
    expect(problem.errors.first.msg, 'invalid');
    expect(problem.errors.first.type, 'value_error');
    expect(problem.errors.last.loc, <Object>['items', 0, 'password']);
    expect(problem.reasons, <String>['UNDER_18', 'PREGNANT']);
  });

  test('malformed errors and reasons do not throw', () {
    final failure = mapResponse(
      _response(
        statusCode: 422,
        data: <String, Object?>{
          'title': 'Validation error',
          'status': 422,
          'code': 'VALIDATION_ERROR',
          'errors': 'nope',
          'reasons': 5,
        },
      ),
    );

    final problem = failure as ApiProblem;
    expect(problem.errors, isEmpty);
    expect(problem.reasons, isNull);

    final mixed = mapResponse(
      _response(
        statusCode: 422,
        data: <String, Object?>{
          'title': 'Validation error',
          'status': 422,
          'code': 'VALIDATION_ERROR',
          'errors': <Object?>[
            'garbage',
            <String, Object?>{'loc': 'email', 'msg': 'x', 'type': 'y'},
            <String, Object?>{
              'loc': <Object>['body', 'password'],
              'msg': 'bad',
              'type': 'value_error',
            },
          ],
          'reasons': <Object?>['OK', 1],
        },
      ),
    ) as ApiProblem;
    expect(mixed.errors, hasLength(1));
    expect(mixed.errors.single.loc, <Object>['body', 'password']);
    expect(mixed.reasons, isNull);
  });
}

Response<dynamic> _response({required int statusCode, Object? data}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/api/v1/auth/register'),
    statusCode: statusCode,
    data: data,
  );
}
