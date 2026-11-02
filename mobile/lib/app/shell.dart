import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/motion.dart';
import '../core/ui/kit.dart';

/// The five tabs with the prototype's floating bar (P2h).
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final items = <NavTab>[
      NavTab(
        l10n.tabToday,
        Icons.wb_sunny_outlined,
        Icons.wb_sunny_rounded,
        'tab-today',
      ),
      NavTab(
        l10n.tabPlan,
        Icons.calendar_month_outlined,
        Icons.calendar_month_rounded,
        'tab-plan',
      ),
      NavTab(
        l10n.tabWater,
        Icons.water_drop_outlined,
        Icons.water_drop_rounded,
        'tab-water',
      ),
      NavTab(
        l10n.tabProgress,
        Icons.insights_outlined,
        Icons.insights_rounded,
        'tab-progress',
      ),
      NavTab(
        l10n.tabMe,
        Icons.person_outline_rounded,
        Icons.person_rounded,
        'tab-me',
      ),
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
      // The bar sits below the content, not over it, so it never hides the
      // last card or a floating button.
      child: Scaffold(
        backgroundColor: colors.bg,
        body: navigationShell,
        bottomNavigationBar: FloatingNavBar(
          tabs: items,
          index: navigationShell.currentIndex,
          onSelect: (int index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}

class NavTab {
  const NavTab(this.label, this.icon, this.selectedIcon, this.keyName);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String keyName;
}

/// `.nav`: a floating rounded bar; a tinted pill slides behind the selected
/// tab; its icon turns filled with a small bounce. No motion with reduced
/// motion.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    required this.tabs,
    required this.index,
    required this.onSelect,
    super.key,
  });

  final List<NavTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;

  static const double radius = 28;
  static const double margin = 12;
  static const double inner = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final animate = animationsEnabled(context);
    final slide = animate ? const Duration(milliseconds: 250) : Duration.zero;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(margin, 4, margin, margin),
        child: DecoratedBox(
          key: const Key('floating-nav'),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: colors.line),
            boxShadow: softShadow(colors),
          ),
          child: Padding(
            padding: const EdgeInsets.all(inner),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final width = constraints.maxWidth / tabs.length;
                return Stack(
                  children: <Widget>[
                    AnimatedPositionedDirectional(
                      key: const Key('nav-pill'),
                      duration: slide,
                      curve: Curves.easeOutCubic,
                      start: width * index,
                      top: 0,
                      bottom: 0,
                      width: width,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: mixColor(colors.brand, 0.13, colors.surface),
                          borderRadius: BorderRadius.circular(radius - inner),
                        ),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        for (final (i, tab) in tabs.indexed)
                          Expanded(
                            child: _NavButton(
                              tab: tab,
                              selected: i == index,
                              animate: animate,
                              onTap: () => onSelect(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.tab,
    required this.selected,
    required this.animate,
    required this.onTap,
  });

  final NavTab tab;
  final bool selected;
  final bool animate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = selected ? colors.brand : colors.fg3;
    final icon = Icon(
      selected ? tab.selectedIcon : tab.icon,
      color: color,
      size: 24,
    );
    return Semantics(
      selected: selected,
      button: true,
      label: tab.label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        key: Key(tab.keyName),
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          FloatingNavBar.radius - FloatingNavBar.inner,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (selected && animate)
                  // `pop`: 0.6 -> 1.15 -> 1 when the tab becomes selected.
                  TweenAnimationBuilder<double>(
                    key: ValueKey<String>('pop-${tab.keyName}'),
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 350),
                    builder: (BuildContext context, double t, Widget? child) {
                      final scale = t < 0.6
                          ? 0.6 + (1.15 - 0.6) * (t / 0.6)
                          : 1.15 - 0.15 * ((t - 0.6) / 0.4);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: icon,
                  )
                else
                  icon,
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: animate
                      ? const Duration(milliseconds: 200)
                      : Duration.zero,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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
