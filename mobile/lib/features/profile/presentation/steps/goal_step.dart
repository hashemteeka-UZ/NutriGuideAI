import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/ui/rise_in.dart';
import '../../domain/pace_rules.dart';
import '../onboarding_controller.dart';
import '../widgets/choice_card.dart';

class GoalStep extends ConsumerWidget {
  const GoalStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final draft = state.draft;
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final sex = draft.sex ?? 'other';
    final goals = state.reference?.goals ?? const <String>[];
    final loseAllowed = loseIsOffered(
      heightCm: draft.heightCm,
      weightKg: draft.weightKg,
    );
    final gainAllowed = gainIsOffered(weightKg: draft.weightKg);
    final options = <_Goal>[
      if (_listed(goals, 'LOSE'))
        _Goal(
          code: 'LOSE',
          emoji: 'chart-decreasing',
          title: l10n.onbGoalLose,
          subtitle: loseAllowed
              ? l10n.onbGoalLoseBody
              : l10n.onbLoseUnavailable,
          enabled: loseAllowed,
        ),
      if (_listed(goals, 'MAINTAIN'))
        _Goal(
          code: 'MAINTAIN',
          emoji: 'balance-scale',
          title: l10n.onbGoalMaintain,
          subtitle: l10n.onbGoalMaintainBody,
          enabled: true,
        ),
      if (_listed(goals, 'GAIN'))
        _Goal(
          code: 'GAIN',
          emoji: 'chart-increasing',
          title: l10n.onbGoalGain,
          subtitle: l10n.onbGoalGainBody,
          enabled: gainAllowed,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RiseIn(
          index: 0,
          child: StepIntro(
            title: l10n.onbGoalTitle(sex),
            subtitle: l10n.onbGoalSubtitle,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < options.length; i++) ...<Widget>[
          RiseIn(
            index: i + 1,
            child: ChoiceCard(
              key: Key('onb-goal-${options[i].code}'),
              emoji: options[i].emoji,
              title: options[i].title,
              subtitle: options[i].subtitle,
              enabled: options[i].enabled,
              selected: draft.goal == options[i].code,
              onTap: () => notifier.setGoal(options[i].code),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

bool _listed(List<String> goals, String code) {
  return goals.isEmpty || goals.contains(code);
}

class _Goal {
  const _Goal({
    required this.code,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  final String code;
  final String emoji;
  final String title;
  final String subtitle;
  final bool enabled;
}
