import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/db/database_key_store.dart';
import 'package:nutriguide/core/db/database_opener.dart';

const _keyA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _keyB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _keyC =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'an encrypted file is not plaintext and a second key cannot open it',
    () async {
      final directory = await Directory.systemTemp.createTemp('ng-k3-enc');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/nutriguide.sqlite');
      final logs = <String>[];
      final previous = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        logs.add(message ?? '');
      };
      try {
        final database = await openEncryptedAppDatabase(
          file: file,
          keys: _Keys(stored: null, created: _keyA),
        );
        await database.customSelect('SELECT 1').get();
        await database.close();

        final header = await file
            .openRead(0, 16)
            .fold<List<int>>(
              <int>[],
              (List<int> previous, List<int> chunk) => previous..addAll(chunk),
            );
        expect(header.length, greaterThanOrEqualTo(15));
        expect(String.fromCharCodes(header.take(15)), isNot('SQLite format 3'));

        await expectLater(
          probeDatabaseKey(file: file, hexKey: _keyB),
          throwsA(isNotNull),
        );
      } finally {
        debugPrint = previous;
      }
      expect(logs.join('\n'), isNot(contains(_keyA)));
      expect(logs.join('\n'), isNot(contains(_keyB)));
    },
  );

  test(
    'a missing key or a key that cannot open the file recreates it',
    () async {
      final directory = await Directory.systemTemp.createTemp('ng-k3-recover');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/nutriguide.sqlite');

      final first = await openEncryptedAppDatabase(
        file: file,
        keys: _Keys(stored: null, created: _keyA),
      );
      await first.close();
      expect(file.existsSync(), isTrue);

      final recovered = await openEncryptedAppDatabase(
        file: file,
        keys: _Keys(stored: null, created: _keyC),
      );
      await recovered
          .customSelect('SELECT count(*) AS n FROM sqlite_master')
          .get();
      await recovered.close();

      await probeDatabaseKey(file: file, hexKey: _keyC);
      await expectLater(
        probeDatabaseKey(file: file, hexKey: _keyA),
        throwsA(isNotNull),
      );

      final wrong = await openEncryptedAppDatabase(
        file: file,
        keys: _Keys(stored: _keyA, created: _keyA, replaced: _keyB),
      );
      await wrong.customSelect('SELECT 1').get();
      await wrong.close();
      await probeDatabaseKey(file: file, hexKey: _keyB);
      await expectLater(
        probeDatabaseKey(file: file, hexKey: _keyC),
        throwsA(isNotNull),
      );
    },
  );
}

final class _Keys implements DatabaseKeyStore {
  _Keys({required this.stored, required this.created, this.replaced});

  String? stored;
  final String created;
  final String? replaced;

  @override
  Future<String?> read() async => stored;

  @override
  Future<String> create() async {
    stored = created;
    return created;
  }

  @override
  Future<String> replace() async {
    final next = replaced ?? created;
    stored = next;
    return next;
  }
}
