import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/database_provider.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/domain/plan_dates.dart';
import '../domain/shopping.dart';
import 'shopping_repository.dart';

abstract interface class TextShare {
  Future<void> share(String text);
}

class SharePlusTextShare implements TextShare {
  const SharePlusTextShare();

  @override
  Future<void> share(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }
}

final textShareProvider = Provider<TextShare>(
  (ref) => const SharePlusTextShare(),
);

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(planApiProvider),
    now: ref.watch(planClockProvider),
  );
});

final shoppingProvider = StreamProvider<ShoppingSnapshot?>((ref) {
  final dates = weekDates(ref.watch(planClockProvider)());
  return ref
      .watch(shoppingRepositoryProvider)
      .watch(from: dates.first, to: dates.last);
});
