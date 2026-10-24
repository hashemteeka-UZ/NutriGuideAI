import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/ui/emoji.dart';
import '../../../../core/ui/rise_in.dart';
import '../onboarding_controller.dart';
import '../widgets/choice_card.dart';

class SafetyStep extends ConsumerWidget {
  const SafetyStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(onboardingControllerProvider).draft;
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final sex = draft.sex ?? 'other';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RiseIn(
          index: 0,
          child: StepIntro(
            title: l10n.onbSafetyTitle,
            subtitle: l10n.onbSafetySubtitle(sex),
          ),
        ),
        const SizedBox(height: 12),
        const Center(child: Emoji('shield', size: 70)),
        const SizedBox(height: 12),
        Text(
          l10n.onbInsulinQuestion(sex),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ChoiceCard(
          key: const Key('onb-insulin-yes'),
          emoji: 'syringe',
          title: l10n.onbYes,
          selected: draft.insulin == true,
          onTap: () => notifier.setInsulin(true),
        ),
        const SizedBox(height: 10),
        ChoiceCard(
          key: const Key('onb-insulin-no'),
          emoji: 'green-heart',
          title: l10n.onbNo,
          selected: draft.insulin == false,
          onTap: () => notifier.setInsulin(false),
        ),
        const SizedBox(height: 8),
        ExplainTile(title: l10n.onbWhyAsk, body: l10n.onbWhyAskBody),
      ],
    );
  }
}
