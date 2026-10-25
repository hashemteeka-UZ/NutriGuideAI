import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../catalog/data/catalog_sync.dart';
import '../../catalog/data/meal_pref_writer.dart';
import '../../catalog/presentation/format_amount.dart';
import '../../catalog/presentation/macro_ring.dart';
import '../../catalog/presentation/meal_detail_screen.dart';
import '../../catalog/presentation/nutrient_labels.dart';
import '../../logging/data/logging_providers.dart';
import '../../logging/domain/logging.dart';
import '../../logging/presentation/eat_button.dart';
import '../../logging/presentation/meal_feedback.dart';
import '../data/plan_providers.dart';
import '../data/plan_sync.dart';
import '../domain/plan.dart';
import '../domain/plan_dates.dart';
import 'plan_format.dart';
import 'reason_chips.dart';

class PlanItemScreen extends ConsumerStatefulWidget {
  const PlanItemScreen({required this.planItemId, super.key});

  final int? planItemId;

  @override
  ConsumerState<PlanItemScreen> createState() => _PlanItemScreenState();
}

class _PlanItemScreenState extends ConsumerState<PlanItemScreen> {
  var _viewed = false;

  /// One VIEW per opening, once the item is known (#267).
  void _queueView(PlanItem item) {
    if (_viewed) {
      return;
    }
    _viewed = true;
    unawaited(
      ref
          .read(interactionQueueProvider)
          .view(mealId: item.mealId, planItemId: item.planItemId)
          .catchError((Object _) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final id = widget.planItemId;
    final item = id == null
        ? null
        : ref.watch(planItemProvider(id)).asData?.value;
    if (item != null) {
      _queueView(item);
    }
    final logs = item == null
        ? const <LoggedMeal>[]
        : ref.watch(dayLogsProvider(item.planDate)).asData?.value ??
              const <LoggedMeal>[];
    final eaten = item != null && isEaten(item, logs);
    final today = isoDate(dateOnly(ref.watch(planClockProvider)()));
    final loggable = item != null && item.planDate == today;
    // ISO dates compare as strings: today or earlier, never a future day (#303).
    final skippable =
        item != null && !eaten && item.planDate.compareTo(today) <= 0;
    final meal = item == null
        ? null
        : ref.watch(mealDetailProvider(item.mealId)).asData?.value;
    final names =
        ref.watch(conditionNamesProvider).asData?.value ??
        const <String, String>{};
    final windows =
        ref.watch(selectedWindowsProvider).asData?.value ?? const [];
    return Scaffold(
      key: const Key('plan-item-screen'),
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.fg,
        title: Text(item?.mealName ?? l10n.tabPlan),
        actions: <Widget>[
          if (meal != null)
            IconButton(
              key: const Key('plan-item-like'),
              tooltip: l10n.mealFavourite,
              onPressed: () {
                unawaited(
                  _stance(
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
      bottomNavigationBar: item == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (loggable)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            EatButton(item: item, ratingScreen: 'plan_item'),
                            if (!eaten) ...<Widget>[
                              const SizedBox(width: 8),
                              Text(l10n.eatAction),
                              const SizedBox(width: 8),
                              TextButton(
                                key: const Key('eat-other-amount'),
                                onPressed: () =>
                                    unawaited(_logAmount(context, ref, item)),
                                child: Text(l10n.eatOtherAmount),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (eaten) ...<Widget>[
                      RateMealRow(item: item),
                      Text(
                        l10n.swapLoggedNote,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.fg2),
                      ),
                    ],
                    if (skippable)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DidNotEatButton(item: item),
                      ),
                    FilledButton(
                      key: const Key('swap-button'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: eaten
                          ? null
                          : () {
                              unawaited(
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (BuildContext context) {
                                    return SwapSheet(
                                      planItemId: item.planItemId,
                                    );
                                  },
                                ),
                              );
                            },
                      child: Text(l10n.swapAction),
                    ),
                  ],
                ),
              ),
            ),
      body: item == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    key: const Key('plan-item-header'),
                    '${slotLabel(l10n, item.slot)} · ${_window(context, windows, item.slot)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.itemPortion(
                      formatAmount(context, item.servingsMultiplier),
                      formatWhole(context, item.grams),
                    ),
                  ),
                  const SizedBox(height: 16),
                  MacroRing(
                    kcal: item.kcal,
                    proteinG: item.proteinG,
                    carbG: item.carbG,
                    fatG: item.fatG,
                    kcalLabel: l10n.mealMacroKcal,
                    proteinLabel: l10n.nutrientProtein,
                    carbLabel: l10n.nutrientCarbs,
                    fatLabel: l10n.nutrientFat,
                    gramsLabel: (double grams) =>
                        l10n.mealServing(formatAmount(context, grams)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.whyChosen,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  ReasonChips(
                    codes: item.reasonCodes,
                    languageCode: Localizations.localeOf(context).languageCode,
                    conditionNames: names,
                    max: item.reasonCodes.length,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.perServingFacts,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (meal != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      l10n.mealServing(
                        formatAmount(context, meal.servingGrams),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.fg2),
                    ),
                    const SizedBox(height: 8),
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
                    if (meal.warningAllergenCodes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          l10n.mealAllergenWarning(
                            meal.warningAllergenCodes
                                .map((String code) => allergenLabel(l10n, code))
                                .join(', '),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.mealIngredients,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final line in meal.ingredients)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: <Widget>[
                            Expanded(child: Text(line.name)),
                            Text(
                              '${l10n.mealServing(formatAmount(context, line.gramsPerServing))} · ${l10n.perServingNote}',
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.mealSteps,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (meal.steps.isEmpty)
                      Text(l10n.mealStepsSoon)
                    else
                      for (var index = 0; index < meal.steps.length; index++)
                        Text('${index + 1}. ${meal.steps[index]}'),
                    TextButton(
                      key: const Key('plan-item-dislike'),
                      onPressed: () {
                        unawaited(
                          _stance(
                            context,
                            ref,
                            meal.mealId,
                            meal.stance == 'DISLIKE' ? null : 'DISLIKE',
                          ),
                        );
                      },
                      child: Text(
                        meal.stance == 'DISLIKE'
                            ? l10n.mealDislikeUndo
                            : l10n.mealDislike,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

Future<void> _logAmount(
  BuildContext context,
  WidgetRef ref,
  PlanItem item,
) async {
  final factor = await showEatAmountSheet(context);
  if (factor == null || !context.mounted) {
    return;
  }
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(loggingRepositoryProvider).logPlanItem(item, factor: factor);
    messenger.showSnackBar(SnackBar(content: Text(l10n.eatSaved)));
  } on Object {
    messenger.showSnackBar(SnackBar(content: Text(l10n.eatFailed)));
    return;
  }
  if (context.mounted) {
    await showRatingSheet(context, ref, item, screen: 'plan_item');
  }
}

String _window(
  BuildContext context,
  List<MealWindowSpan> windows,
  String slot,
) {
  for (final window in windows) {
    if (window.slot == slot) {
      return '${formatHm(context, window.start)}–${formatHm(context, window.end)}';
    }
  }
  return '';
}

Future<void> _stance(
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

class SwapSheet extends ConsumerStatefulWidget {
  const SwapSheet({required this.planItemId, super.key});

  final int planItemId;

  @override
  ConsumerState<SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends ConsumerState<SwapSheet> {
  List<PlanAlternative>? _items;
  String? _error;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final items = await ref
          .read(planRepositoryProvider)
          .alternatives(widget.planItemId);
      if (mounted) {
        setState(() => _items = items);
      }
    } on PlanRequestException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.network
              ? AppLocalizations.of(context).swapOffline
              : AppLocalizations.of(context).genGeneric;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final items = _items;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.swapTitle,
              key: const Key('swap-sheet'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(l10n.swapSubtitle, style: TextStyle(color: colors.fg2)),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, key: const Key('swap-error'))
            else if (items == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              Text(l10n.swapEmpty, key: const Key('swap-empty'))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) {
                    final alternative = items[index];
                    return ListTile(
                      key: Key('swap-${alternative.mealId}'),
                      enabled: !_busy,
                      title: Text(alternative.name),
                      subtitle: Text(formatWhole(context, alternative.kcal)),
                      trailing: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          formatDelta(context, alternative.kcalDelta),
                        ),
                      ),
                      onTap: () => unawaited(_choose(alternative)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _choose(PlanAlternative alternative) async {
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(planRepositoryProvider)
          .swap(planItemId: widget.planItemId, mealId: alternative.mealId);
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.swapDone)));
    } on PlanRequestException catch (error) {
      if (!mounted) {
        return;
      }
      await _handle(error);
    }
  }

  Future<void> _handle(PlanRequestException error) async {
    final l10n = AppLocalizations.of(context);
    switch (error.code) {
      case 'PLAN_ITEM_NOT_FOUND':
        await ref.read(planSyncProvider).refresh();
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      case 'MEAL_NOT_FOUND':
        final lang = Localizations.localeOf(context).languageCode;
        await ref.read(catalogSyncProvider).sync(lang: lang);
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      case 'SWAP_REJECTED':
        setState(() {
          _busy = false;
          _error = l10n.failureSwapRejected;
        });
        return;
      case 'PLAN_ITEM_ALREADY_LOGGED':
        setState(() {
          _busy = false;
          _error = l10n.failurePlanItemAlreadyLogged;
        });
        return;
      default:
        setState(() {
          _busy = false;
          _error = error.network ? l10n.swapOffline : l10n.genGeneric;
        });
    }
  }
}
