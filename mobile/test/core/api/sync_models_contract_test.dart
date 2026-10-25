import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/api/manual/sync_models.dart';

/// The hand-written sync operations (Decision #262) checked key by key
/// against docs/api/openapi.json.
void main() {
  final openapi = jsonDecode(
    File('../docs/api/openapi.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final schemas =
      (openapi['components']! as Map<String, Object?>)['schemas']!
          as Map<String, Object?>;

  Map<String, Object?> schema(String name) {
    return schemas[name]! as Map<String, Object?>;
  }

  Map<String, Object?> resolve(Map<String, Object?> node) {
    final ref = node[r'$ref'];
    if (ref is String) {
      return schema(ref.split('/').last);
    }
    return node;
  }

  /// Required keys present, no key the schema does not declare, and each
  /// const or enum value allowed.
  void conforms(Map<String, Object?> json, String name) {
    final shape = schema(name);
    final properties = shape['properties']! as Map<String, Object?>;
    final required = (shape['required'] as List<Object?>? ?? const [])
        .cast<String>();
    for (final key in required) {
      expect(json.containsKey(key), isTrue, reason: '$name needs $key');
    }
    for (final entry in json.entries) {
      expect(
        properties.containsKey(entry.key),
        isTrue,
        reason: '$name has no ${entry.key}',
      );
      final property = resolve(properties[entry.key]! as Map<String, Object?>);
      final constant = property['const'];
      if (constant != null) {
        expect(entry.value, constant, reason: '$name.${entry.key}');
      }
      final allowed = property['enum'];
      if (allowed is List) {
        expect(allowed, contains(entry.value), reason: '$name.${entry.key}');
      }
      if (property['format'] == 'date-time') {
        expect('${entry.value}', endsWith('Z'), reason: '$name.${entry.key}');
      }
      if (property['format'] == 'date') {
        expect(
          '${entry.value}',
          matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
          reason: '$name.${entry.key}',
        );
      }
    }
  }

  const opId = '6f1b9c3e-8a2d-4e55-9c1a-2b7d0e4f8a10';
  const clientUuid = '0d5f2a8e-3c1b-4d7e-9a6f-1e2b3c4d5e6f';
  final at = DateTime(2026, 10, 25, 8, 15);

  test('PLAN_ITEM create matches SyncConsumptionCreate and PlanItemLog', () {
    final json = PlanItemLogCreateOp(
      opId: opId,
      clientUuid: clientUuid,
      planItemId: 5,
      servingsConsumed: 1,
      consumedAt: at,
    ).toJson();
    conforms(json, 'SyncConsumptionCreate');
    conforms(json['log']! as Map<String, Object?>, 'PlanItemLog');
  });

  test('MEAL create matches SyncConsumptionCreate and MealLog', () {
    final json = MealLogCreateOp(
      opId: opId,
      clientUuid: clientUuid,
      mealId: 42,
      servingsConsumed: 0.5,
      consumedAt: at,
      slot: 'LUNCH',
    ).toJson();
    conforms(json, 'SyncConsumptionCreate');
    conforms(json['log']! as Map<String, Object?>, 'MealLog');
    final log = json['log']! as Map<String, Object?>;
    final slots = schema('MealSlot')['enum']! as List<Object?>;
    expect(slots, contains(log['slot']));
  });

  test('CONSUMPTION_DELETE matches SyncConsumptionDelete', () {
    conforms(
      const ConsumptionDeleteOp(opId: opId, logId: 21).toJson(),
      'SyncConsumptionDelete',
    );
  });

  test('WATER_CREATE matches SyncWaterCreate', () {
    conforms(
      WaterCreateOp(
        opId: opId,
        clientUuid: clientUuid,
        amountMl: 250,
        consumedAt: at,
      ).toJson(),
      'SyncWaterCreate',
    );
  });

  test('WATER_DELETE matches SyncWaterDelete', () {
    conforms(
      const WaterDeleteOp(opId: opId, logId: 3).toJson(),
      'SyncWaterDelete',
    );
  });

  test('WEIGHT_PUT matches SyncWeightPut', () {
    conforms(
      WeightPutOp(
        opId: opId,
        measuredOn: '2026-10-25',
        weightKg: 79.5,
        updatedAt: at,
      ).toJson(),
      'SyncWeightPut',
    );
  });

  test('INTERACTION_CREATE matches SyncInteractionCreate', () {
    final json = const InteractionCreateOp(
      opId: opId,
      clientUuid: clientUuid,
      mealId: 42,
      eventType: 'IMPRESSION',
      planItemId: 5,
      screen: 'today',
    ).toJson();
    conforms(json, 'SyncInteractionCreate');
    expect(json.containsKey('value'), isFalse);
  });

  test('every op type of the batch union has a model', () {
    final batch = schema('SyncBatch')['properties']! as Map<String, Object?>;
    final items =
        (batch['operations']! as Map<String, Object?>)['items']!
            as Map<String, Object?>;
    final mapping =
        (items['discriminator']! as Map<String, Object?>)['mapping']!
            as Map<String, Object?>;
    final written = <String>{
      PlanItemLogCreateOp(
        opId: opId,
        clientUuid: clientUuid,
        planItemId: 1,
        servingsConsumed: 1,
        consumedAt: at,
      ).op,
      const ConsumptionDeleteOp(opId: opId, logId: 1).op,
      WaterCreateOp(
        opId: opId,
        clientUuid: clientUuid,
        amountMl: 250,
        consumedAt: at,
      ).op,
      const WaterDeleteOp(opId: opId, logId: 1).op,
      WeightPutOp(
        opId: opId,
        measuredOn: '2026-10-25',
        weightKg: 80,
        updatedAt: at,
      ).op,
      const InteractionCreateOp(
        opId: opId,
        clientUuid: clientUuid,
        mealId: 1,
        eventType: 'VIEW',
      ).op,
    };
    // CONSUMPTION_CORRECT is not used by the app yet.
    expect(
      mapping.keys.toSet().difference(<String>{'CONSUMPTION_CORRECT'}),
      written,
    );
  });

  test('results parse, and an unknown status is kept as rejected', () {
    final example = schema('SyncResult')['example']! as Map<String, Object?>;
    final result = SyncBatchResult.fromJson(example);
    expect(result.results.single.status, SyncOpStatus.created);
    expect(result.results.single.entityId, 21);
    expect(result.serverTime, DateTime.utc(2026, 10, 20, 8, 16));

    final rejected = SyncOpOutcome.fromJson(const <String, Object?>{
      'op_id': opId,
      'status': 'REJECTED',
      'code': 'PLAN_ITEM_NOT_FOUND',
    });
    expect(rejected.stored, isFalse);
    expect(rejected.code, 'PLAN_ITEM_NOT_FOUND');
    final odd = SyncOpOutcome.fromJson(const <String, Object?>{
      'op_id': opId,
      'status': 'SOMETHING_NEW',
    });
    expect(odd.status, SyncOpStatus.rejected);
    final duplicate = SyncOpOutcome.fromJson(const <String, Object?>{
      'op_id': opId,
      'status': 'DUPLICATE',
      'entity_id': 9,
    });
    expect(duplicate.stored, isTrue);
  });
}
