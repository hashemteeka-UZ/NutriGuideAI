import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/domain/plan.dart';
import '../../plan/domain/plan_dates.dart';
import '../../plan/presentation/offline_bar.dart';
import '../../plan/presentation/plan_format.dart';
import '../data/shopping_providers.dart';
import '../domain/shopping.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_refresh()));
  }

  Future<void> _refresh() async {
    final dates = weekDates(ref.read(planClockProvider)());
    try {
      await ref
          .read(shoppingRepositoryProvider)
          .refresh(from: dates.first, to: dates.last);
      ref.read(planOfflineProvider.notifier).setOffline(false);
    } on PlanRequestException catch (error) {
      if (error.network) {
        ref.read(planOfflineProvider.notifier).setOffline(true);
      }
    } on Object {
      ref.read(planOfflineProvider.notifier).setOffline(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final snapshot = ref.watch(shoppingProvider).asData?.value;
    final dates = weekDates(ref.watch(planClockProvider)());
    return Scaffold(
      key: const Key('shopping-screen'),
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.fg,
        title: Text(l10n.shopTitle),
        actions: <Widget>[
          if (snapshot != null)
            IconButton(
              key: const Key('shop-share'),
              tooltip: l10n.shopShare,
              onPressed: () {
                final text = shoppingShareText(
                  header: l10n.shopShareHeader(
                    isoDate(dates.first),
                    isoDate(dates.last),
                  ),
                  items: snapshot.items,
                  quantity: (ShoppingRow row) => _qty(context, row.grams),
                );
                unawaited(ref.read(textShareProvider).share(text));
              },
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const OfflineBar(),
          Expanded(
            child: snapshot == null
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.shopNeedsNet,
                      key: const Key('shop-needs-net'),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(l10n.shopNote),
                        const SizedBox(height: 12),
                        Text(
                          l10n.shopProgress(
                            snapshot.checkedCount,
                            snapshot.items.length,
                          ),
                          key: const Key('shop-progress'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: snapshot.items.isEmpty
                              ? 0
                              : snapshot.checkedCount / snapshot.items.length,
                        ),
                        const SizedBox(height: 12),
                        for (final row in snapshot.items)
                          CheckboxListTile(
                            key: Key('shop-item-${row.ingredientId}'),
                            value: row.checked,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(row.name),
                            subtitle: Text(
                              '${_qty(context, row.grams)} · ${l10n.shopInMeals(row.meals)}',
                            ),
                            onChanged: (bool? value) {
                              unawaited(
                                ref
                                    .read(shoppingRepositoryProvider)
                                    .setChecked(
                                      rangeKey: snapshot.rangeKey,
                                      ingredientId: row.ingredientId,
                                      checked: value ?? false,
                                    ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

String _qty(BuildContext context, double grams) {
  final l10n = AppLocalizations.of(context);
  final quantity = shoppingQuantity(grams);
  if (quantity.kilograms) {
    return l10n.shopKg(formatFixed(context, quantity.amount, 1));
  }
  return l10n.shopGrams(formatWhole(context, quantity.amount));
}
