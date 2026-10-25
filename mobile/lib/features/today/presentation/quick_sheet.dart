import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../weight/presentation/weight_sheet.dart';

/// «ماذا تريد أن تضيف؟» from the Today FAB (Decision #273). The shopping
/// tile shows only when a plan exists.
Future<void> showQuickSheet(BuildContext context, {required bool hasPlan}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final router = GoRouter.of(context);
      void then(void Function() action) {
        Navigator.pop(sheetContext);
        action();
      }

      return SafeArea(
        child: Padding(
          key: const Key('quick-sheet'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.quickTitle,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 104,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  _Tile(
                    key: const Key('quick-water'),
                    icon: Icons.water_drop_outlined,
                    label: l10n.quickWater,
                    onTap: () => then(() => router.go('/water')),
                  ),
                  _Tile(
                    key: const Key('quick-meal'),
                    icon: Icons.restaurant_outlined,
                    label: l10n.otherMealTitle,
                    onTap: () =>
                        then(() => unawaited(router.push('/log/meal'))),
                  ),
                  _Tile(
                    key: const Key('quick-weight'),
                    icon: Icons.monitor_weight_outlined,
                    label: l10n.weightTitle,
                    onTap: () =>
                        then(() => unawaited(showWeightSheet(context))),
                  ),
                  if (hasPlan)
                    _Tile(
                      key: const Key('quick-shopping'),
                      icon: Icons.shopping_basket_outlined,
                      label: l10n.shopTitle,
                      onTap: () => then(() => router.go('/plan/shopping')),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: colors.brand, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
