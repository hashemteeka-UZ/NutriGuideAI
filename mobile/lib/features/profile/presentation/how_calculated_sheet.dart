import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/profile_result.dart';
import 'format_number.dart';

Future<void> showHowCalculated(
  BuildContext context, {
  required DailyTarget target,
  required String goalType,
}) {
  final lines = calculationLines(target: target, goalType: goalType);
  final colors = context.appColors;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: colors.surface,
    builder: (BuildContext context) {
      return HowCalculatedSheet(lines: lines, goalType: goalType);
    },
  );
}

class HowCalculatedSheet extends StatelessWidget {
  const HowCalculatedSheet({
    required this.lines,
    required this.goalType,
    super.key,
  });

  final List<CalcLine> lines;
  final String goalType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          Text(
            l10n.onbHowTitle,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final line in lines) ...<Widget>[
            _Line(line: line, goalType: goalType),
            Divider(color: colors.line, height: 20),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line, required this.goalType});

  final CalcLine line;
  final String goalType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final copy = _copy(context, l10n);
    return Column(
      key: Key('calc-${line.kind.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                copy.title,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatMeasure(context, line.primary),
              style: colors.numeric.copyWith(
                fontWeight: FontWeight.w700,
                color: line.kind == CalcLineKind.daily
                    ? colors.kcal
                    : colors.fg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          copy.body,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.fg2, height: 1.4),
        ),
      ],
    );
  }

  ({String title, String body}) _copy(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    switch (line.kind) {
      case CalcLineKind.resting:
        return (title: l10n.onbHowRestTitle, body: l10n.onbHowRestBody);
      case CalcLineKind.activity:
        final factor = line.secondary == null
            ? '—'
            : formatCount(context, line.secondary!, fractionDigits: 2);
        return (
          title: l10n.onbHowActivityTitle,
          body: l10n.onbHowActivityBody(factor),
        );
      case CalcLineKind.adjustment:
        final lose = goalType == 'LOSE';
        return (
          title: lose ? l10n.onbHowDeficitTitle : l10n.onbHowSurplusTitle,
          body: lose ? l10n.onbHowDeficitBody : l10n.onbHowSurplusBody,
        );
      case CalcLineKind.floor:
        return (title: l10n.onbHowFloorTitle, body: l10n.onbHowFloorBody);
      case CalcLineKind.daily:
        final weight = line.secondary == null
            ? '—'
            : formatMeasure(context, line.secondary!);
        return (title: l10n.onbHowDailyTitle, body: l10n.onbHowBasedOn(weight));
    }
  }
}
