import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/emoji.dart';
import '../data/catalog_providers.dart';
import '../data/meal_pref_writer.dart';
import '../domain/meal.dart';
import 'format_amount.dart';
import 'macro_ring.dart';
import 'nutrient_labels.dart';

final mealDetailProvider = FutureProvider.autoDispose.family<MealDetail?, int>((
  ref,
  int mealId,
) {
  ref.watch(mealRevisionProvider);
  return ref.watch(catalogRepositoryProvider).detail(mealId);
});

class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({required this.mealId, super.key});

  final int? mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final id = mealId;
    final detail = id == null ? null : ref.watch(mealDetailProvider(id));
    final meal = detail?.asData?.value;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.fg,
        title: Text(meal?.name ?? l10n.browseMeals),
        actions: <Widget>[
          if (meal != null)
            IconButton(
              key: const Key('meal-like'),
              tooltip: l10n.mealFavourite,
              onPressed: () {
                unawaited(
                  _apply(
                    context,
                    ref,
                    meal.mealId,
                    meal.stance == 'LIKE' ? null : 'LIKE',
                  ),
                );
              },
              icon: Icon(
                meal.stance == 'LIKE' ? Icons.favorite : Icons.favorite_border,
                color: meal.stance == 'LIKE' ? colors.protein : colors.fg,
              ),
            ),
        ],
      ),
      body: id == null
          ? Center(child: Text(l10n.failureMealNotFound))
          : detail!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stack) =>
                  Center(child: Text(l10n.mealPrefSaveFailed)),
              data: (MealDetail? meal) {
                if (meal == null) {
                  return Center(child: Text(l10n.failureMealNotFound));
                }
                return _Detail(meal: meal);
              },
            ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.meal});

  final MealDetail meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final separator = Localizations.localeOf(context).languageCode == 'ar'
        ? '، '
        : ', ';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        Container(
          height: 170,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[colors.heroStart, colors.surface],
            ),
          ),
          child: Emoji(meal.iconName, size: 88),
        ),
        const SizedBox(height: 16),
        Text(
          meal.name,
          style: text.headlineSmall?.copyWith(
            color: colors.fg,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          <String>[
            if (meal.cuisineName != null) meal.cuisineName!,
            l10n.mealServing(formatAmount(context, meal.servingGrams)),
          ].join(' · '),
          style: text.bodyMedium?.copyWith(color: colors.fg2),
        ),
        if (meal.warningAllergenCodes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Container(
            key: const Key('meal-allergen-warning'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.danger.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: <Widget>[
                const Emoji('warning', size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.mealAllergenWarning(
                      meal.warningAllergenCodes
                          .map((String code) => allergenLabel(l10n, code))
                          .join(separator),
                    ),
                    style: text.bodyMedium?.copyWith(color: colors.fg),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                MacroRing(
                  kcal: meal.kcal,
                  proteinG: meal.proteinG,
                  carbG: meal.carbG,
                  fatG: meal.fatG,
                  kcalLabel: l10n.mealMacroKcal,
                  proteinLabel: l10n.nutrientProtein,
                  carbLabel: l10n.nutrientCarbs,
                  fatLabel: l10n.nutrientFat,
                  gramsLabel: (double grams) =>
                      l10n.mealServing(formatAmount(context, grams)),
                ),
                if (meal.sodiumPerServing != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _absolute(
                    context,
                    l10n.mealSodium,
                    '${formatAmount(context, meal.sodiumPerServing!)} ${l10n.mealMg}',
                  ),
                ],
                if (meal.saturatedFatPerServing != null) ...<Widget>[
                  const SizedBox(height: 8),
                  _absolute(
                    context,
                    l10n.mealSaturatedFat,
                    l10n.mealServing(
                      formatAmount(context, meal.saturatedFatPerServing!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          key: const Key('meal-facts'),
          title: Text(l10n.mealFacts),
          children: <Widget>[
            for (final nutrient in meal.nutrients)
              ListTile(
                dense: true,
                title: Text(nutrientLabel(l10n, nutrient.code)),
                trailing: Text(
                  _nutrientValue(context, l10n, nutrient),
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        Text(
          l10n.mealIngredients,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        for (final item in meal.ingredients)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    item.isOptional
                        ? '${item.name} · ${l10n.mealOptional}'
                        : item.name,
                    style: text.bodyLarge,
                  ),
                ),
                Text(
                  l10n.mealServing(formatAmount(context, item.gramsPerServing)),
                  style: text.bodyMedium?.copyWith(color: colors.fg2),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          l10n.mealSteps,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (meal.steps.isEmpty)
          Text(
            l10n.mealStepsSoon,
            key: const Key('meal-steps-soon'),
            style: text.bodyLarge?.copyWith(color: colors.fg2),
          )
        else
          for (var i = 0; i < meal.steps.length; i++)
            Padding(
              key: Key('meal-step-$i'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}.',
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(child: Text(meal.steps[i], style: text.bodyLarge)),
                ],
              ),
            ),
        const SizedBox(height: 12),
        TextButton(
          key: const Key('meal-dislike'),
          onPressed: () {
            unawaited(
              _apply(
                context,
                ref,
                meal.mealId,
                meal.stance == 'DISLIKE' ? null : 'DISLIKE',
              ),
            );
          },
          child: Text(
            meal.stance == 'DISLIKE' ? l10n.mealDislikeUndo : l10n.mealDislike,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

Widget _absolute(BuildContext context, String label, String value) {
  final colors = context.appColors;
  return Row(
    children: <Widget>[
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.fg),
        ),
      ),
      Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

String _nutrientValue(
  BuildContext context,
  AppLocalizations l10n,
  NutrientLine nutrient,
) {
  final amount = nutrient.perServing;
  if (amount == null) {
    return '—';
  }
  return '${formatAmount(context, amount)} ${unitLabel(l10n, nutrient.unit)}';
}

Future<void> _apply(
  BuildContext context,
  WidgetRef ref,
  int mealId,
  String? stance,
) async {
  try {
    await ref
        .read(mealPrefWriterProvider)
        .apply(mealId: mealId, stance: stance);
  } on Object {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).mealPrefSaveFailed)),
    );
  }
}
