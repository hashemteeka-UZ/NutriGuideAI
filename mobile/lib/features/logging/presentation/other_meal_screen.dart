import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../catalog/data/catalog_providers.dart';
import '../../catalog/data/meal_pref_writer.dart';
import '../../catalog/domain/meal.dart';
import '../../catalog/presentation/meal_card.dart';
import '../../catalog/presentation/meals_controller.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/domain/plan.dart';
import '../../plan/presentation/plan_format.dart';
import '../data/logging_providers.dart';

/// «أكلت وجبة أخرى»: pick from the local catalog (Decision #272). Meals
/// with an avoided allergen keep their K.3 warning badge.
class OtherMealScreen extends ConsumerWidget {
  const OtherMealScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final state = ref.watch(mealsControllerProvider);
    final meals = state.page?.meals ?? const <MealSummary>[];
    return Scaffold(
      key: const Key('other-meal-screen'),
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.fg,
        title: Text(l10n.otherMealTitle),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const Key('other-meal-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.mealSearchHint,
              ),
              onChanged: (String text) {
                ref.read(mealsControllerProvider.notifier).setSearch(text);
              },
            ),
          ),
          Expanded(
            child: state.loading && meals.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: meals.length,
                    itemBuilder: (BuildContext context, int index) {
                      final meal = meals[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MealCard(
                          key: Key('other-meal-${meal.mealId}'),
                          meal: meal,
                          onOpen: () => unawaited(_choose(context, ref, meal)),
                          onHeart: () {
                            unawaited(
                              ref
                                  .read(mealPrefWriterProvider)
                                  .apply(
                                    mealId: meal.mealId,
                                    stance: meal.liked ? null : 'LIKE',
                                  )
                                  .catchError((Object _) {}),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    MealSummary meal,
  ) async {
    final detail = await ref
        .read(catalogRepositoryProvider)
        .detail(meal.mealId);
    if (detail == null || !context.mounted) {
      return;
    }
    final choice = await showOtherMealSheet(
      context,
      defaultSlot: currentSlot(ref),
    );
    if (choice == null || !context.mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(loggingRepositoryProvider)
          .logMeal(
            mealId: detail.mealId,
            name: detail.name,
            servings: choice.servings,
            slot: choice.slot,
            kcalPerServing: detail.kcal,
            proteinPerServing: detail.proteinG,
            carbPerServing: detail.carbG,
            fatPerServing: detail.fatG,
          );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.eatSaved)));
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.eatFailed)));
    }
  }
}

/// The slot whose window holds the current time, else the nearest one.
String currentSlot(WidgetRef ref) {
  final now = ref.read(planClockProvider)();
  final minutes = now.hour * 60 + now.minute;
  final windows =
      ref.read(todayWindowsProvider).asData?.value ?? const <MealWindowSpan>[];
  for (final window in windows) {
    final start = _minutes(window.start);
    final end = _minutes(window.end);
    if (minutes >= start && minutes <= end) {
      return window.slot;
    }
  }
  if (minutes < 11 * 60) {
    return 'BREAKFAST';
  }
  if (minutes < 16 * 60) {
    return 'LUNCH';
  }
  if (minutes < 18 * 60) {
    return 'SNACK';
  }
  return 'DINNER';
}

int _minutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) {
    return 0;
  }
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

const otherMealServings = <double>[0.5, 1, 1.5, 2];

/// Servings ½, 1, 1½, 2 (default 1) and the slot.
Future<({double servings, String slot})?> showOtherMealSheet(
  BuildContext context, {
  required String defaultSlot,
}) {
  return showModalBottomSheet<({double servings, String slot})>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => _OtherMealSheet(slot: defaultSlot),
  );
}

class _OtherMealSheet extends StatefulWidget {
  const _OtherMealSheet({required this.slot});

  final String slot;

  @override
  State<_OtherMealSheet> createState() => _OtherMealSheetState();
}

class _OtherMealSheetState extends State<_OtherMealSheet> {
  var _servings = 1.0;
  late String _slot = widget.slot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        key: const Key('other-meal-sheet'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.otherMealServings,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final servings in otherMealServings)
                  ChoiceChip(
                    key: Key('other-servings-$servings'),
                    label: Text(_servingsLabel(servings)),
                    selected: _servings == servings,
                    onSelected: (_) => setState(() => _servings = servings),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.otherMealSlot,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final slot in slotOrder)
                  ChoiceChip(
                    key: Key('other-slot-$slot'),
                    label: Text(slotLabel(l10n, slot)),
                    selected: _slot == slot,
                    onSelected: (_) => setState(() => _slot = slot),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('other-meal-log'),
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () {
                Navigator.pop(context, (servings: _servings, slot: _slot));
              },
              child: Text(l10n.missedAction),
            ),
          ],
        ),
      ),
    );
  }
}

String _servingsLabel(double servings) {
  return switch (servings) {
    0.5 => '½',
    1.5 => '1½',
    _ => servings.toStringAsFixed(0),
  };
}

/// ½, 1, 1½ or 2 as shown in lists.
String servingsLabel(double servings) => _servingsLabel(servings);
