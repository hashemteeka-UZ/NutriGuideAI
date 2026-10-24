import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/rise_in.dart';
import '../../domain/pace_rules.dart';
import '../format_number.dart';
import '../onboarding_controller.dart';
import '../widgets/choice_card.dart';
import '../widgets/wheel_picker.dart';

class PaceStep extends ConsumerWidget {
  const PaceStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(onboardingControllerProvider).draft;
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final today = ref.watch(onboardingNowProvider)();
    final sex = draft.sex ?? 'other';
    final gain = draft.goal == 'GAIN';
    final bounds = targetWeightBounds(
      goal: draft.goal,
      heightCm: draft.heightCm,
      weightKg: draft.weightKg,
    );
    final rates = rateChoices(goal: draft.goal, weightKg: draft.weightKg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RiseIn(
          index: 0,
          child: StepIntro(
            title: gain
                ? l10n.onbPaceGainTitle(sex)
                : l10n.onbPaceLoseTitle(sex),
            subtitle: l10n.onbPaceSubtitle(sex),
            badge: '${l10n.onbJustForYou} · ${l10n.onbBecauseWeight}',
          ),
        ),
        const SizedBox(height: 12),
        if (bounds != null && draft.targetWeightKg != null)
          RiseIn(
            index: 1,
            child: Column(
              children: <Widget>[
                Text(
                  '${l10n.onbTargetWeight} (${l10n.onbKg})',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                NumberWheel(
                  min: bounds.minKg,
                  max: bounds.maxKg,
                  step: 0.5,
                  fractionDigits: 1,
                  value: draft.targetWeightKg!,
                  semanticLabel: l10n.onbTargetWeight,
                  onChanged: notifier.setTargetWeight,
                ),
                if (!gain)
                  Text(
                    l10n.onbLoseUnavailable,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: context.appColors.fg2),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          l10n.onbPaceHeading,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < rates.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RiseIn(
              index: i + 2,
              child: ChoiceCard(
                key: Key('onb-rate-${rates[i].rateKg}'),
                emoji: _emoji(rates[i].rateKg),
                title: _title(l10n, rates[i].rateKg),
                subtitle: rates[i].enabled
                    ? _body(l10n, rates[i].rateKg)
                    : l10n.onbRateUnavailable,
                enabled: rates[i].enabled,
                selected: draft.weeklyRateKg == rates[i].rateKg,
                onTap: () => notifier.setRate(rates[i].rateKg),
              ),
            ),
          ),
        if (gain) TipBanner(emoji: 'shield', text: l10n.onbGainCap),
        if (draft.targetWeightKg != null &&
            draft.weeklyRateKg != null) ...<Widget>[
          const SizedBox(height: 8),
          TipBanner(
            emoji: 'spiral-calendar',
            text: l10n.onbArrival(
              sex,
              formatMeasure(context, draft.targetWeightKg!),
              formatCount(
                context,
                estimatedWeeks(
                  currentKg: draft.weightKg,
                  targetKg: draft.targetWeightKg!,
                  weeklyRateKg: draft.weeklyRateKg!,
                ),
              ),
              _when(
                context,
                estimatedArrival(
                  today,
                  estimatedWeeks(
                    currentKg: draft.weightKg,
                    targetKg: draft.targetWeightKg!,
                    weeklyRateKg: draft.weeklyRateKg!,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

String _when(BuildContext context, DateTime date) {
  final locale = localeNameOf(context);
  final month = DateFormat.MMMM(locale).format(date);
  final year = DateFormat.y(locale).format(date);
  return '$month $year';
}

String _emoji(double rate) {
  if (rate == 0.25) {
    return 'seedling';
  }
  if (rate == 0.5) {
    return 'bullseye';
  }
  if (rate == 0.75) {
    return 'person-running';
  }
  return 'rocket';
}

String _title(AppLocalizations l10n, double rate) {
  if (rate == 0.25) {
    return l10n.onbRateGentle;
  }
  if (rate == 0.5) {
    return l10n.onbRateBalanced;
  }
  if (rate == 0.75) {
    return l10n.onbRateFaster;
  }
  return l10n.onbRateMax;
}

String _body(AppLocalizations l10n, double rate) {
  if (rate == 0.25) {
    return l10n.onbRateGentleBody;
  }
  if (rate == 0.5) {
    return l10n.onbRateBalancedBody;
  }
  if (rate == 0.75) {
    return l10n.onbRateFasterBody;
  }
  return l10n.onbRateMaxBody;
}
