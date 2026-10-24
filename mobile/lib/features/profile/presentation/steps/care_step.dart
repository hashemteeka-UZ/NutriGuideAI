import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/ui/rise_in.dart';
import '../../../reference/domain/reference_data.dart';
import '../onboarding_controller.dart';
import '../widgets/choice_card.dart';

class CareStep extends ConsumerWidget {
  const CareStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final sex = state.draft.sex ?? 'other';
    final conditions =
        state.reference?.supportedConditions ?? const <ConditionInfo>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RiseIn(
          index: 0,
          child: StepIntro(
            title: l10n.onbCareTitle(sex),
            subtitle: l10n.onbCareSubtitle(sex),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < conditions.length; i++) ...<Widget>[
          RiseIn(
            index: i + 1,
            child: ChoiceCard(
              key: Key('onb-care-${conditions[i].code}'),
              emoji: conditionEmoji(conditions[i].code),
              title: conditions[i].name,
              subtitle: conditionSubtitle(l10n, conditions[i].code),
              selected: state.draft.conditionCodes.contains(conditions[i].code),
              onTap: () => notifier.toggleCondition(conditions[i].code),
            ),
          ),
          const SizedBox(height: 10),
        ],
        RiseIn(
          index: conditions.length + 1,
          child: ChoiceCard(
            key: const Key('onb-care-NONE'),
            emoji: 'green-salad',
            title: l10n.onbCareNone,
            subtitle: l10n.onbCareNoneBody,
            selected: state.draft.declinedConditions,
            onTap: notifier.declineConditions,
          ),
        ),
        const SizedBox(height: 8),
        ExplainTile(
          title: l10n.onbCareExplainTitle,
          body: l10n.onbCareExplainBody,
        ),
      ],
    );
  }
}

String conditionEmoji(String code) {
  return switch (code) {
    'DIABETES_T2' => 'drop-of-blood',
    'HYPERTENSION' => 'salt',
    'HEART_DISEASE' => 'red-heart',
    _ => 'shield',
  };
}

String? conditionSubtitle(AppLocalizations l10n, String code) {
  return switch (code) {
    'DIABETES_T2' => l10n.onbCareDiabetesBody,
    'HYPERTENSION' => l10n.onbCarePressureBody,
    'HEART_DISEASE' => l10n.onbCareHeartBody,
    _ => null,
  };
}
