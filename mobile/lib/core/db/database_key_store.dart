import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_store.dart';

abstract interface class DatabaseKeyStore {
  static const storageKey = 'db_key_v1';

  Future<String?> read();

  Future<String> create();

  Future<String> replace();
}

final class SecureDatabaseKeyStore implements DatabaseKeyStore {
  SecureDatabaseKeyStore(this._storage, {Random? random})
    : _random = random ?? Random.secure();

  final SecureKeyValue _storage;
  final Random _random;

  @override
  Future<String?> read() async {
    final stored = await _storage.read(DatabaseKeyStore.storageKey);
    if (stored == null || stored.isEmpty) {
      return null;
    }
    return stored;
  }

  @override
  Future<String> create() async {
    final hex = _hexKey(_random);
    await _storage.write(DatabaseKeyStore.storageKey, hex);
    return hex;
  }

  @override
  Future<String> replace() async {
    try {
      await _storage.delete(DatabaseKeyStore.storageKey);
    } on Object {
      // A broken keystore still gets a new key written below.
    }
    return create();
  }
}

String _hexKey(Random random) {
  final buffer = StringBuffer();
  for (var i = 0; i < 32; i++) {
    buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

final databaseKeyStoreProvider = Provider<DatabaseKeyStore>((ref) {
  return SecureDatabaseKeyStore(ref.watch(secureStoreProvider));
});
