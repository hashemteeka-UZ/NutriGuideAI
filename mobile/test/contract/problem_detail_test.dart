import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/generated/models/problem_detail.dart';

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
}
