import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final items = <_Tab>[
      _Tab(
        0,
        l10n.tabToday,
        Icons.wb_sunny_outlined,
        Icons.wb_sunny,
        'tab-today',
      ),
      _Tab(
        1,
        l10n.tabPlan,
        Icons.calendar_month_outlined,
        Icons.calendar_month,
        'tab-plan',
      ),
      _Tab(
        2,
        l10n.tabWater,
        Icons.water_drop_outlined,
        Icons.water_drop,
        'tab-water',
      ),
      _Tab(
        3,
        l10n.tabProgress,
        Icons.insights_outlined,
        Icons.insights,
        'tab-progress',
      ),
      _Tab(4, l10n.tabMe, Icons.person_outline, Icons.person, 'tab-me'),
    ];
    return PopScope(
      key: const Key('app-shell'),
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        navigationShell.goBranch(0);
      },
      child: Scaffold(
        backgroundColor: colors.bg,
        body: navigationShell,
        bottomNavigationBar: Material(
          color: colors.surface,
          child: SafeArea(
            child: Row(
              children: <Widget>[
                for (final item in items)
                  Expanded(
                    child: Semantics(
                      selected: navigationShell.currentIndex == item.index,
                      button: true,
                      label: item.label,
                      child: InkWell(
                        key: Key(item.keyName),
                        onTap: () {
                          navigationShell.goBranch(
                            item.index,
                            initialLocation:
                                item.index == navigationShell.currentIndex,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                navigationShell.currentIndex == item.index
                                    ? item.selected
                                    : item.icon,
                                color:
                                    navigationShell.currentIndex == item.index
                                    ? colors.brand
                                    : colors.fg3,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color:
                                          navigationShell.currentIndex ==
                                              item.index
                                          ? colors.brand
                                          : colors.fg3,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _Tab {
  const _Tab(this.index, this.label, this.icon, this.selected, this.keyName);

  final int index;
  final String label;
  final IconData icon;
  final IconData selected;
  final String keyName;
}
