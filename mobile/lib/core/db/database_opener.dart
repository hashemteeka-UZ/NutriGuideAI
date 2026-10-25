import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'app_database.dart';
import 'database_key_store.dart';

final _keyPattern = RegExp(r'^[0-9a-f]{64}$');

/// Thrown when the stored key cannot read the database file.
final class DatabaseKeyError implements Exception {
  const DatabaseKeyError();

  @override
  String toString() => 'DatabaseKeyError';
}

/// Opens [file] with the stored key. A missing key beside an existing file,
/// or a key that cannot read the file, deletes it and creates a new encrypted
/// database. The catalog and profile can be downloaded again.
///
/// The key is set and checked on the same connection. A failed check closes
/// that connection, deletes the file, and opens a new one.
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
  return _RecoveringExecutor(file: file, keys: keys, hexKey: active);
}

Future<AppDatabase> openEncryptedAppDatabase({
  required File file,
  required DatabaseKeyStore keys,
}) async {
  final database = AppDatabase(
    await openEncryptedExecutor(file: file, keys: keys),
  );
  await database.customSelect('SELECT count(*) AS n FROM sqlite_master').get();
  return database;
}

/// Opens [file] with [hexKey] and reads `sqlite_master`. Does not recover.
Future<void> probeDatabaseKey({
  required File file,
  required String hexKey,
}) async {
  final executor = encryptedExecutor(file, hexKey);
  try {
    await executor.ensureOpen(const _KeyProbe());
  } finally {
    await executor.close();
  }
}

QueryExecutor encryptedExecutor(File file, String hexKey) {
  return NativeDatabase.createInBackground(
    file,
    setup: (database) {
      // The key is the first statement. Nothing may run before it.
      database.execute("PRAGMA hexkey = '$hexKey'");
      try {
        database.select('SELECT count(*) AS n FROM sqlite_master');
      } on SqliteException {
        throw const DatabaseKeyError();
      }
    },
  );
}

/// The real database user opens this executor once. Setup checks the key on
/// that connection. A bad key closes it, deletes the file, and opens again
/// with a new key for the same user, so migrations run only on the new file.
final class _RecoveringExecutor extends QueryExecutor {
  _RecoveringExecutor({
    required File file,
    required this._keys,
    required String hexKey,
  }) : _file = file,
       _inner = encryptedExecutor(file, hexKey);

  final File _file;
  final DatabaseKeyStore _keys;
  QueryExecutor _inner;
  var _replaced = false;

  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async {
    try {
      return await _inner.ensureOpen(user);
    } catch (error) {
      if (_replaced || !_isKeyError(error)) {
        rethrow;
      }
      _replaced = true;
      await _inner.close();
      await deleteDatabaseFiles(_file);
      final fresh = await _keys.replace();
      _inner = encryptedExecutor(_file, fresh);
      return _inner.ensureOpen(user);
    }
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) {
    return _inner.runSelect(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) {
    return _inner.runInsert(statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) {
    return _inner.runUpdate(statement, args);
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) {
    return _inner.runDelete(statement, args);
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) {
    return _inner.runCustom(statement, args);
  }

  @override
  Future<void> runBatched(BatchedStatements statements) {
    return _inner.runBatched(statements);
  }

  @override
  TransactionExecutor beginTransaction() => _inner.beginTransaction();

  @override
  QueryExecutor beginExclusive() => _inner.beginExclusive();

  @override
  Future<void> close() => _inner.close();
}

bool _isKeyError(Object error) {
  return error is DatabaseKeyError ||
      error.toString().contains('DatabaseKeyError');
}

/// Reads an already-migrated file. Does not create tables.
final class _KeyProbe implements QueryExecutorUser {
  const _KeyProbe();

  @override
  int get schemaVersion => 3;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

Future<void> deleteDatabaseFiles(File file) async {
  for (final suffix in const <String>['', '-wal', '-shm', '-journal']) {
    final candidate = File('${file.path}$suffix');
    if (candidate.existsSync()) {
      await candidate.delete();
    }
  }
}
