import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import 'database_key_store.dart';
import 'database_opener.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final keys = ref.watch(databaseKeyStoreProvider);
  final database = AppDatabase(
    LazyDatabase(() async {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(p.join(directory.path, 'nutriguide.sqlite'));
      return openEncryptedExecutor(file: file, keys: keys);
    }),
  );
  ref.onDispose(() {
    unawaited(database.close());
  });
  return database;
});
