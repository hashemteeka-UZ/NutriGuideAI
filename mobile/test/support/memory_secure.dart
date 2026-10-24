import 'package:nutriguide/core/storage/secure_store.dart';

class MemorySecure implements SecureKeyValue {
  final values = <String, String>{};
  var throwReads = false;
  var throwDeletes = false;
  final deleted = <String>[];

  @override
  Future<String?> read(String key) async {
    if (throwReads) {
      throw StateError('keystore');
    }
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deleted.add(key);
    if (throwDeletes) {
      throw StateError('keystore');
    }
    values.remove(key);
  }
}
