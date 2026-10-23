import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/server_check/domain/server_status.dart';

void main() {
  test('only API major version 1 is compatible', () {
    expect(isCompatibleApiVersion('1.0.0'), isTrue);
    expect(isCompatibleApiVersion('1.2.3'), isTrue);
    expect(isCompatibleApiVersion('1'), isTrue);
    expect(isCompatibleApiVersion('2.0.0'), isFalse);
    expect(isCompatibleApiVersion('0.9.0'), isFalse);
    expect(isCompatibleApiVersion('10.0.0'), isFalse);
    expect(isCompatibleApiVersion(''), isFalse);
    expect(isCompatibleApiVersion('v1.0.0'), isFalse);
  });

  test('needsUpdate follows the major version', () {
    const compatible = ServerStatus(
      apiVersion: '1.0.0',
      datasetVersion: 'catalog_v3',
      plannerName: 'cpsat',
    );
    const broken = ServerStatus(
      apiVersion: '2.0.0',
      datasetVersion: null,
      plannerName: 'cpsat',
    );
    expect(compatible.needsUpdate, isFalse);
    expect(broken.needsUpdate, isTrue);
  });
}
