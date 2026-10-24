import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/locale/locale_controller.dart';
import '../domain/catalog_repository.dart';
import 'catalog_repository_impl.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  ref.watch(localeProvider);
  final code = ref.watch(localeCodeProvider);
  return CatalogRepositoryImpl(
    ref.watch(appDatabaseProvider),
    locale: () => code.code,
  );
});
