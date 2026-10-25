import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../plan/domain/plan.dart';
import '../data/logging_providers.dart';

/// Ratings given in this run of the app, by plan item (#302). Not stored:
/// after a restart the stars are empty, and a new rating is a new event.
class PlanItemRatings extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => const <int, int>{};

  void set(int planItemId, int value) {
    state = <int, int>{...state, planItemId: value};
  }
}

final planItemRatingsProvider =
    NotifierProvider<PlanItemRatings, Map<int, int>>(PlanItemRatings.new);

/// Plan items marked «لم آكلها» in this run of the app (#303).
class SkippedPlanItems extends Notifier<Set<int>> {
  @override
  Set<int> build() => const <int>{};

  void add(int planItemId) {
    state = <int>{...state, planItemId};
  }
}

final skippedPlanItemsProvider = NotifierProvider<SkippedPlanItems, Set<int>>(
  SkippedPlanItems.new,
);

/// Five 48 dp stars; [value] 0 means none chosen yet.
class StarRating extends StatelessWidget {
  const StarRating({
    required this.value,
    required this.onChanged,
    this.keyPrefix = 'rate-star',
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var star = 1; star <= 5; star++)
          Semantics(
            button: true,
            selected: star <= value,
            label: l10n.rateStar(star),
            excludeSemantics: true,
            child: IconButton(
              key: Key('$keyPrefix-$star'),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Icon(
                star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: star <= value ? colors.carb : colors.fg2,
                size: 32,
              ),
              onPressed: () => onChanged(star),
            ),
          ),
      ],
    );
  }
}

/// Queues a RATE and remembers it for the plan item screen.
Future<void> ratePlanItem(
  WidgetRef ref,
  PlanItem item,
  int value, {
  required String screen,
}) async {
  ref.read(planItemRatingsProvider.notifier).set(item.planItemId, value);
  await ref
      .read(interactionQueueProvider)
      .rate(
        mealId: item.mealId,
        value: value,
        planItemId: item.planItemId,
        screen: screen,
      );
}

/// «كيف كانت الوجبة؟» after a plan item is logged (#302).
Future<void> showRatingSheet(
  BuildContext context,
  WidgetRef ref,
  PlanItem item, {
  required String screen,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  // «سجلتها» would sit over the sheet's buttons; the sheet confirms the log.
  messenger?.hideCurrentSnackBar();
  final value = await showModalBottomSheet<int>(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Padding(
          key: const Key('rating-sheet'),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.rateTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(item.mealName, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              StarRating(
                value: 0,
                keyPrefix: 'sheet-star',
                onChanged: (int star) => Navigator.pop(context, star),
              ),
              TextButton(
                key: const Key('rating-later'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.rateLater),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (value == null) {
    return;
  }
  try {
    await ratePlanItem(ref, item, value, screen: screen);
    messenger?.showSnackBar(SnackBar(content: Text(l10n.rateThanks)));
  } on Object {
    // A rating that could not be queued is not worth an error for the user.
  }
}

/// «قيّم الوجبة» on the plan item screen of a logged item (#302).
class RateMealRow extends ConsumerWidget {
  const RateMealRow({required this.item, super.key});

  final PlanItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(planItemRatingsProvider)[item.planItemId] ?? 0;
    return Row(
      key: const Key('rate-meal-row'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(l10n.rateThisMeal),
        const SizedBox(width: 4),
        Flexible(
          child: FittedBox(
            child: StarRating(
              value: value,
              onChanged: (int star) {
                unawaited(_rate(context, ref, star));
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _rate(BuildContext context, WidgetRef ref, int value) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ratePlanItem(ref, item, value, screen: 'plan_item');
      messenger?.showSnackBar(SnackBar(content: Text(l10n.rateThanks)));
    } on Object {
      // Kept quiet, as in the sheet.
    }
  }
}

/// «لم آكلها» for a past or today's unlogged item (#303).
class DidNotEatButton extends ConsumerWidget {
  const DidNotEatButton({required this.item, super.key});

  final PlanItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    if (ref.watch(skippedPlanItemsProvider).contains(item.planItemId)) {
      return Center(
        child: Chip(
          key: const Key('did-not-eat-marked'),
          avatar: Icon(Icons.check, size: 16, color: colors.fg2),
          label: Text(l10n.didNotEatMarked),
        ),
      );
    }
    return OutlinedButton(
      key: const Key('did-not-eat'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      onPressed: () => unawaited(_confirm(context, ref)),
      child: Text(l10n.didNotEat),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          key: const Key('did-not-eat-dialog'),
          content: Text(l10n.didNotEatConfirm),
          actions: <Widget>[
            TextButton(
              key: const Key('did-not-eat-cancel'),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.didNotEatCancel),
            ),
            FilledButton(
              key: const Key('did-not-eat-continue'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.didNotEatContinue),
            ),
          ],
        );
      },
    );
    if (ok != true) {
      return;
    }
    ref.read(skippedPlanItemsProvider.notifier).add(item.planItemId);
    try {
      await ref
          .read(interactionQueueProvider)
          .skip(
            planItemId: item.planItemId,
            mealId: item.mealId,
            date: item.planDate,
          );
    } on Object {
      // The chip stays: the same id is derived on the next tap after a restart.
    }
  }
}
