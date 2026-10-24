import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'presentation and domain stay free of data, storage, and generated clients',
    () {
      final root = Directory('lib/features');
      expect(root.existsSync(), isTrue);
      expect(Directory('lib/features/catalog').existsSync(), isTrue);
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
              target.contains('package:flutter_secure_storage') ||
              target.contains('package:drift') ||
              target.contains('package:sqlite3') ||
              target.contains('core/db/') ||
              target.contains('core/api/generated')) {
            violations.add('$normalized -> $target');
          }
        }
      }

      expect(violations, isEmpty);
    },
  );

  test('aggregate generated clients stay inside the generated folder', () {
    final roots = <Directory>[Directory('lib'), Directory('test')];
    final importPattern = RegExp(
      '^\\s*(?:import|export)\\s+[\'"]([^\'"]+)[\'"]',
      multiLine: true,
    );
    const forbidden = <String>[
      'generated/export.dart',
      'generated/rest_client.dart',
      'generated/clients/sync_client.dart',
    ];
    final violations = <String>[];

    for (final root in roots) {
      if (!root.existsSync()) {
        continue;
      }
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final normalized = entity.path.replaceAll('\\', '/');
        if (normalized.contains('/lib/core/api/generated/')) {
          continue;
        }
        final source = entity.readAsStringSync();
        for (final match in importPattern.allMatches(source)) {
          final target = match.group(1)!;
          if (forbidden.any(target.contains)) {
            violations.add('$normalized -> $target');
          }
        }
      }
    }

    expect(violations, isEmpty);
  });
}
