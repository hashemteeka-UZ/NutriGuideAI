import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'app_database.dart';
import 'database_key_store.dart';

final _keyPattern = RegExp(r'^[0-9a-f]{64}$');

/// Opens [file] with the stored key. A missing key beside an existing file,
/// or a key that cannot read the file, deletes it and creates a new encrypted
/// database. The catalog and profile can be downloaded again.
Future<QueryExecutor> openEncryptedExecutor({
  required File file,
  required DatabaseKeyStore keys,
}) async {
  final stored = await keys.read();
  final key = stored != null && _keyPattern.hasMatch(stored) ? stored : null;
  if (key == null && file.existsSync()) {
    await deleteDatabaseFiles(file);
  }
  final active = key ?? await keys.create();
  try {
    await _probe(file, active);
    return encryptedExecutor(file, active);
  } on Object {
    await deleteDatabaseFiles(file);
    final fresh = await keys.replace();
    await _probe(file, fresh);
    return encryptedExecutor(file, fresh);
  }
}

Future<AppDatabase> openEncryptedAppDatabase({
  required File file,
  required DatabaseKeyStore keys,
}) async {
  return AppDatabase(await openEncryptedExecutor(file: file, keys: keys));
}

/// Opens [file] with [hexKey] and reads `sqlite_master`. Does not recover.
Future<void> probeDatabaseKey({required File file, required String hexKey}) {
  return _probe(file, hexKey);
}

QueryExecutor encryptedExecutor(File file, String hexKey) {
  return NativeDatabase.createInBackground(
    file,
    setup: (database) {
      // The key is the first statement. Nothing may run before it.
      database.execute("PRAGMA hexkey = '$hexKey'");
    },
  );
}

Future<void> _probe(File file, String hexKey) async {
  final database = AppDatabase(encryptedExecutor(file, hexKey));
  try {
    await database
        .customSelect('SELECT count(*) AS n FROM sqlite_master')
        .get();
  } catch (_) {
    await database.close();
    rethrow;
  }
  await database.close();
}

Future<void> deleteDatabaseFiles(File file) async {
  for (final suffix in const <String>['', '-wal', '-shm', '-journal']) {
    final candidate = File('${file.path}$suffix');
    if (candidate.existsSync()) {
      await candidate.delete();
    }
  }
}
