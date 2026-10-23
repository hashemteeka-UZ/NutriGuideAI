import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation and domain do not import dio or generated clients', () {
    final root = Directory('lib/features');
    expect(root.existsSync(), isTrue);
    final importPattern = RegExp(
      '^\\s*(?:import|export)\\s+[\'"]([^\'"]+)[\'"]',
      multiLine: true,
    );
    final violations = <String>[];

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final normalized = entity.path.replaceAll('\\', '/');
      final inCheckedLayer =
          normalized.contains('/presentation/') ||
          normalized.contains('/domain/');
      if (!inCheckedLayer) {
        continue;
      }
      final source = entity.readAsStringSync();
      for (final match in importPattern.allMatches(source)) {
        final target = match.group(1)!;
        if (target.contains('package:dio') ||
            target.contains('core/api/generated')) {
          violations.add('$normalized -> $target');
        }
      }
    }

    expect(violations, isEmpty);
  });
}
