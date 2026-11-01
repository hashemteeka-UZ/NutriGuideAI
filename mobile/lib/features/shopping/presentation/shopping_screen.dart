import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../../core/ui/emoji.dart';
import '../../../core/ui/kit.dart';
import '../../../core/ui/rise_in.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/domain/plan.dart';
import '../../plan/domain/plan_dates.dart';
import '../../plan/presentation/offline_bar.dart';
import '../../plan/presentation/plan_format.dart';
import '../data/shopping_providers.dart';
import '../domain/shopping.dart';

/// Shopping list like the prototype `shop()` (P2b): a hero with the progress
/// ring, three scopes, one card per food group, and a collapsible «bought»
/// section. Ticks are shared by the three scopes for the plan week.
class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  /// Rows ticked a moment ago: drawn as checked while they slide away.
  final Set<int> _leaving = <int>{};
  bool _boughtOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_refresh()));
  }

  Future<void> _refresh() async {
    final now = ref.read(planClockProvider)();
    final dates = weekDates(now);
    final today = dateOnly(now);
    final repository = ref.read(shoppingRepositoryProvider);
    try {
      await repository.refresh(from: dates.first, to: dates.last);
      await repository.refresh(from: today, to: today);
      ref.read(planOfflineProvider.notifier).setOffline(false);
    } on PlanRequestException catch (error) {
      if (error.network) {
        ref.read(planOfflineProvider.notifier).setOffline(true);
      }
    } on Object {
      ref.read(planOfflineProvider.notifier).setOffline(true);
    }
  }

  Future<void> _setChecked(ShoppingRow row, bool checked) async {
    final repository = ref.read(shoppingRepositoryProvider);
    final weekKey = ref.read(shoppingWeekKeyProvider);
    if (!checked) {
      await repository.setChecked(
        weekKey: weekKey,
        ingredientId: row.ingredientId,
        checked: false,
      );
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final animate = animationsEnabled(context);
    setState(() => _leaving.add(row.ingredientId));
    if (animate) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
    }
    await repository.setChecked(
      weekKey: weekKey,
      ingredientId: row.ingredientId,
      checked: true,
    );
    if (!mounted) {
      return;
    }
    setState(() => _leaving.remove(row.ingredientId));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('shop-undo-bar'),
          content: Text(l10n.shopMarked),
          // With an action a SnackBar stays until dismissed by default.
          persist: false,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: l10n.shopUndo,
            onPressed: () => unawaited(
              repository.setChecked(
                weekKey: weekKey,
                ingredientId: row.ingredientId,
                checked: false,
              ),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final scope = ref.watch(shoppingScopeProvider);
    final view = _view(scope);
    final rows = view.rows;
    final done = rows?.where((ShoppingRow row) => row.checked).length ?? 0;
    final total = rows?.length ?? 0;
    return Scaffold(
      key: const Key('shopping-screen'),
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.fg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.shopTitle),
            Text(
              l10n.shopSubtitle,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.fg3),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          const OfflineBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: <Widget>[
                RiseIn(
                  index: 0,
                  child: _Hero(
                    done: done,
                    total: total,
                    onShare: rows == null || done == total
                        ? null
                        : () => _share(rows),
                  ),
                ),
                const SizedBox(height: 12),
                RiseIn(
                  index: 1,
                  child: Center(
                    child: SegToggle<ShoppingScope>(
                      key: const Key('shop-scope'),
                      options: <(ShoppingScope, String)>[
                        (ShoppingScope.plan, l10n.shopScopePlan),
                        (ShoppingScope.today, l10n.shopScopeToday),
                        (ShoppingScope.meal, l10n.shopScopeMeal),
                      ],
                      value: scope,
                      onChanged: (ShoppingScope next) {
                        ref.read(shoppingScopeProvider.notifier).select(next);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (view.meal != null) ...<Widget>[
                  _MealHeader(meal: view.meal!),
                  const SizedBox(height: 12),
                ],
                ..._body(context, scope, view),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({List<ShoppingRow>? rows, CurrentMealShopping? meal, bool loading}) _view(
    ShoppingScope scope,
  ) {
    switch (scope) {
      case ShoppingScope.plan:
        final value = ref.watch(shoppingProvider);
        return (
          rows: value.asData?.value?.items,
          meal: null,
          loading: value.isLoading,
        );
      case ShoppingScope.today:
        final value = ref.watch(todayShoppingProvider);
        return (
          rows: value.asData?.value?.items,
          meal: null,
          loading: value.isLoading,
        );
      case ShoppingScope.meal:
        final value = ref.watch(currentMealShoppingProvider);
        final meal = value.asData?.value;
        return (
          rows: meal?.rows ?? (value.hasValue ? const <ShoppingRow>[] : null),
          meal: meal,
          loading: value.isLoading && !value.hasValue,
        );
    }
  }

  List<Widget> _body(
    BuildContext context,
    ShoppingScope scope,
    ({List<ShoppingRow>? rows, CurrentMealShopping? meal, bool loading}) view,
  ) {
    final l10n = AppLocalizations.of(context);
    final rows = view.rows;
    if (rows == null) {
      if (view.loading) {
        return const <Widget>[
          Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      }
      return <Widget>[
        _Empty(
          key: const Key('shop-needs-net'),
          emoji: 'shopping-cart',
          text: l10n.shopNeedsNet,
        ),
      ];
    }
    if (rows.isEmpty) {
      return <Widget>[
        _Empty(
          key: const Key('shop-empty'),
          emoji: 'shopping-cart',
          title: l10n.shopEmptyTitle,
          text: switch (scope) {
            ShoppingScope.plan => l10n.shopEmptyPlan,
            ShoppingScope.today => l10n.shopEmptyToday,
            ShoppingScope.meal => l10n.shopEmptyMeal,
          },
        ),
      ];
    }
    final open = <ShoppingRow>[
      for (final row in rows)
        if (!row.checked) row,
    ];
    final bought = <ShoppingRow>[
      for (final row in rows)
        if (row.checked) row,
    ];
    final groups = groupShopping(open);
    return <Widget>[
      if (open.isEmpty)
        _Empty(
          key: const Key('shop-all-bought'),
          emoji: 'party-popper',
          text: l10n.shopAllBought,
        ),
      for (final (index, group) in groups.indexed) ...<Widget>[
        RiseIn(
          index: index + 2,
          child: _GroupCard(
            key: Key('shop-group-${group.code}'),
            group: group,
            leaving: _leaving,
            quantity: (ShoppingRow row) => _qty(context, row.grams),
            onTap: (ShoppingRow row) => unawaited(_setChecked(row, true)),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (bought.isNotEmpty)
        _BoughtSection(
          rows: bought,
          open: _boughtOpen,
          onToggle: () => setState(() => _boughtOpen = !_boughtOpen),
          quantity: (ShoppingRow row) => _qty(context, row.grams),
          onTap: (ShoppingRow row) => unawaited(_setChecked(row, false)),
        ),
    ];
  }

  void _share(List<ShoppingRow> rows) {
    final l10n = AppLocalizations.of(context);
    final scope = ref.read(shoppingScopeProvider);
    final now = ref.read(planClockProvider)();
    final dates = scope == ShoppingScope.plan
        ? weekDates(now)
        : <DateTime>[dateOnly(now)];
    final text = shoppingShareText(
      header: l10n.shopShareHeader(isoDate(dates.first), isoDate(dates.last)),
      items: rows,
      quantity: (ShoppingRow row) => _qty(context, row.grams),
      groupName: (ShoppingGroup group) =>
          group.name.isEmpty ? l10n.shopAllItems : group.name,
    );
    unawaited(ref.read(textShareProvider).share(text));
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.done, required this.total, this.onShare});

  final int done;
  final int total;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final share = total == 0 ? 0.0 : done / total;
    return GradientHero(
      child: Row(
        children: <Widget>[
          RingPercent(
            value: share,
            size: 64,
            stroke: 7,
            color: Colors.white,
            track: Colors.white.withValues(alpha: 0.25),
            center: const Emoji('shopping-cart', size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.shopProgress(done, total),
              key: const Key('shop-progress'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            key: const Key('shop-share'),
            tooltip: l10n.shopShare,
            onPressed: onShare,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
            ),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
    );
  }
}

class _MealHeader extends StatelessWidget {
  const _MealHeader({required this.meal});

  final CurrentMealShopping meal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    // Isolated left-to-right so «07:30–09:30» keeps its order in Arabic.
    final time = meal.start == null
        ? ''
        : ' · $_lri${meal.start}–${meal.end}$_pdi';
    return AppCard(
      key: const Key('shop-meal'),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          EmojiTile(
            meal.item.iconName ?? 'fork-and-knife-with-plate',
            size: 52,
            tint: colors.kcal,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${meal.now ? l10n.shopMealNow : l10n.shopMealNext}$time',
                  style: TextStyle(fontSize: 12.5, color: colors.fg3),
                ),
                Text(
                  meal.item.mealName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.leaving,
    required this.quantity,
    required this.onTap,
    super.key,
  });

  final ShoppingGroup group;
  final Set<int> leaving;
  final String Function(ShoppingRow row) quantity;
  final ValueChanged<ShoppingRow> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final name = group.name.isEmpty ? l10n.shopAllItems : group.name;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: _Resize(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Emoji(categoryEmoji(group.code), size: 22),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.shopGroupCount(group.rows.length),
                      style: colors.numeric.copyWith(color: colors.fg3),
                    ),
                  ],
                ),
              ),
            ),
            for (final row in group.rows)
              _ShopRow(
                key: Key('shop-item-${row.ingredientId}'),
                row: row,
                checked: leaving.contains(row.ingredientId),
                quantity: quantity(row),
                onTap: () => onTap(row),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({
    required this.row,
    required this.checked,
    required this.quantity,
    required this.onTap,
    super.key,
  });

  final ShoppingRow row;
  final bool checked;
  final String quantity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final animate = animationsEnabled(context);
    final duration = animate
        ? const Duration(milliseconds: 220)
        : Duration.zero;
    return Semantics(
      checked: checked,
      label: l10n.shopItemSemantics(row.name, quantity),
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: checked ? 0.55 : 1,
          duration: duration,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: duration,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checked ? colors.ok : Colors.transparent,
                    border: Border.all(
                      color: checked ? colors.ok : colors.fg3,
                      width: 2,
                    ),
                  ),
                  child: checked
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        row.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.fg,
                          decoration: checked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(
                        l10n.shopInMeals(row.meals),
                        style: TextStyle(fontSize: 12, color: colors.fg3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  quantity,
                  style: colors.numeric.copyWith(
                    color: colors.fg2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoughtSection extends StatelessWidget {
  const _BoughtSection({
    required this.rows,
    required this.open,
    required this.onToggle,
    required this.quantity,
    required this.onTap,
  });

  final List<ShoppingRow> rows;
  final bool open;
  final VoidCallback onToggle;
  final String Function(ShoppingRow row) quantity;
  final ValueChanged<ShoppingRow> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final duration = animationsEnabled(context)
        ? const Duration(milliseconds: 260)
        : Duration.zero;
    return AppCard(
      key: const Key('shop-bought'),
      flat: true,
      background: colors.surface2,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: _Resize(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              button: true,
              expanded: open,
              child: InkWell(
                key: const Key('shop-bought-toggle'),
                onTap: onToggle,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.check_circle, color: colors.ok, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.shopBought(rows.length),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: duration,
                        child: Icon(Icons.expand_more, color: colors.fg3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (open)
              for (final row in rows)
                _ShopRow(
                  key: Key('shop-bought-${row.ingredientId}'),
                  row: row,
                  checked: true,
                  quantity: quantity(row),
                  onTap: () => onTap(row),
                ),
          ],
        ),
      ),
    );
  }
}

/// Animates height changes; none with reduce motion (a zero-length
/// AnimatedSize re-dirties its own layout).
class _Resize extends StatelessWidget {
  const _Resize({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animationsEnabled(context)) {
      return child;
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: AlignmentDirectional.topCenter,
      child: child,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.emoji,
    required this.text,
    this.title,
    super.key,
  });

  final String emoji;
  final String? title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: <Widget>[
          EmojiTile(emoji, size: 96, tint: colors.kcal),
          const SizedBox(height: 14),
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.fg2),
          ),
        ],
      ),
    );
  }
}

/// Left-to-right isolate (U+2066) and its closing mark (U+2069).
final String _lri = String.fromCharCode(0x2066);
final String _pdi = String.fromCharCode(0x2069);

String _qty(BuildContext context, double grams) {
  final l10n = AppLocalizations.of(context);
  final quantity = shoppingQuantity(grams);
  if (quantity.kilograms) {
    return l10n.shopKg(formatFixed(context, quantity.amount, 1));
  }
  return l10n.shopGrams(formatWhole(context, quantity.amount));
}
