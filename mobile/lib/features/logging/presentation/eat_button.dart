import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../../core/ui/kit.dart';
import '../../plan/domain/plan.dart';
import '../data/logging_providers.dart';
import '../domain/logging.dart';
import 'meal_feedback.dart';
import 'rejected_messages.dart';

/// The round «أكلتها» button (`.eat`). Tap logs the planned portion now;
/// long-press offers another amount. Once logged it shows a check and
/// «تراجع».
class EatButton extends ConsumerWidget {
  const EatButton({
    required this.item,
    this.consumedAt,
    this.ratingScreen = 'today',
    super.key,
  });

  final PlanItem item;

  /// When the meal was eaten; now when null.
  final DateTime? consumedAt;

  /// `screen` of the RATE asked for after logging (#302).
  final String ratingScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final logs =
        ref.watch(dayLogsProvider(item.planDate)).asData?.value ??
        const <LoggedMeal>[];
    final state = logStateOf(item, logs);
    final eaten =
        state == PlanItemLogState.pending ||
        state == PlanItemLogState.confirmed;
    final duration = animationsEnabled(context)
        ? const Duration(milliseconds: 220)
        : Duration.zero;
    final Widget child;
    if (state == PlanItemLogState.rejected) {
      child = IconButton(
        key: Key('eat-rejected-${item.planItemId}'),
        tooltip: l10n.syncRejected,
        icon: Icon(Icons.error_outline, color: colors.protein),
        onPressed: () => showRejectedLogs(context, ref),
      );
    } else if (eaten) {
      final log = logForItem(item.planItemId, logs);
      child = Row(
        key: Key('eat-done-${item.planItemId}'),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            label: l10n.eatLogged,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.brand,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.check_rounded, color: colors.onBrand),
            ),
          ),
          if (log != null)
            TextButton(
              key: Key('eat-undo-${item.planItemId}'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => unawaited(_undo(context, ref)),
              child: Text(l10n.eatUndo),
            ),
        ],
      );
    } else {
      child = Semantics(
        button: true,
        label: l10n.eatAction,
        excludeSemantics: true,
        child: Tooltip(
          message: l10n.eatAction,
          child: InkResponse(
            key: Key('eat-${item.planItemId}'),
            radius: 28,
            borderRadius: BorderRadius.circular(16),
            onTap: () => unawaited(_log(context, ref, 1)),
            onLongPress: () => unawaited(_chooseAmount(context, ref)),
            child: CustomPaint(
              painter: DashedBorderPainter(
                color: mixColor(colors.brand, 0.6, colors.line),
                dashed: true,
                width: 1.5,
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.add_rounded, color: colors.brand),
              ),
            ),
          ),
        ),
      );
    }
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: child,
    );
  }

  Future<void> _log(BuildContext context, WidgetRef ref, double factor) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final haptics = animationsEnabled(context);
    try {
      await ref
          .read(loggingRepositoryProvider)
          .logPlanItem(item, factor: factor, consumedAt: consumedAt);
      if (haptics) {
        unawaited(HapticFeedback.lightImpact());
      }
      messenger?.showSnackBar(SnackBar(content: Text(l10n.eatSaved)));
    } on Object {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.eatFailed)));
      return;
    }
    if (context.mounted) {
      await showRatingSheet(context, ref, item, screen: ratingScreen);
    }
  }

  Future<void> _undo(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    await ref.read(loggingRepositoryProvider).undo(item.planItemId);
    messenger?.showSnackBar(SnackBar(content: Text(l10n.eatUndone)));
  }

  Future<void> _chooseAmount(BuildContext context, WidgetRef ref) async {
    final factor = await showEatAmountSheet(context);
    if (factor == null || !context.mounted) {
      return;
    }
    await _log(context, ref, factor);
  }
}

/// «كمية مختلفة»: ½, 1 or 1½ of the planned portion.
Future<double?> showEatAmountSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final labels = <double, String>{
    0.5: l10n.eatAmountHalf,
    1: l10n.eatAmountFull,
    1.5: l10n.eatAmountOneHalf,
  };
  return showModalBottomSheet<double>(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          key: const Key('eat-amount-sheet'),
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.eatAmountTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final factor in portionFactors)
              ListTile(
                key: Key('eat-amount-$factor'),
                minTileHeight: 48,
                title: Text(labels[factor] ?? '$factor'),
                onTap: () => Navigator.pop(context, factor),
              ),
          ],
        ),
      );
    },
  );
}
