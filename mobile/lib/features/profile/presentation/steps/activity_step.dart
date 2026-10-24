import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/ui/rise_in.dart';
import '../onboarding_controller.dart';
import '../widgets/choice_card.dart';

class ActivityStep extends ConsumerWidget {
  const ActivityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final sex = state.draft.sex ?? 'other';
    final known = state.reference?.activityLevels ?? const <String>[];
    final options = <_Activity>[
      for (final option in _options(l10n))
        if (known.isEmpty || known.contains(option.code)) option,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RiseIn(
          index: 0,
          child: StepIntro(
            title: l10n.onbActivityTitle(sex),
            subtitle: l10n.onbActivitySubtitle(sex),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < options.length; i++) ...<Widget>[
          RiseIn(
            index: i + 1,
            child: ChoiceCard(
              key: Key('onb-activity-${options[i].code}'),
              emoji: options[i].emoji,
              title: options[i].title,
              subtitle: options[i].subtitle,
              selected: state.draft.activity == options[i].code,
              onTap: () => notifier.setActivity(options[i].code),
            ),
          ),
          const SizedBox(height: 10),
        ],
        RiseIn(
          index: options.length + 1,
          child: TipBanner(emoji: 'light-bulb', text: l10n.onbActivityTip(sex)),
        ),
      ],
    );
  }
}

class _Activity {
  const _Activity(this.code, this.emoji, this.title, this.subtitle);

  final String code;
  final String emoji;
  final String title;
  final String subtitle;
}

List<_Activity> _options(AppLocalizations l10n) {
  return <_Activity>[
    _Activity(
      'SEDENTARY',
      'chair',
      l10n.onbActSedentary,
      l10n.onbActSedentaryBody,
    ),
    _Activity(
      'LIGHT',
      'person-walking',
      l10n.onbActLight,
      l10n.onbActLightBody,
    ),
    _Activity(
      'MODERATE',
      'person-biking',
      l10n.onbActModerate,
      l10n.onbActModerateBody,
    ),
    _Activity('HIGH', 'person-running', l10n.onbActHigh, l10n.onbActHighBody),
    _Activity(
      'ATHLETE',
      'person-lifting-weights',
      l10n.onbActAthlete,
      l10n.onbActAthleteBody,
    ),
  ];
}
