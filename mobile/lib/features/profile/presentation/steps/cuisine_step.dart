import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/ui/rise_in.dart';
import '../onboarding_controller.dart';
import '../widgets/choice_card.dart';

/// Preferred cuisines. The planner gives their dishes a bonus and never
/// drops the others, because each cuisine has a different number of meals.
class CuisineStep extends ConsumerWidget {
  const CuisineStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final listed = state.reference?.cuisines ?? const [];
    final codes = <String>[
      for (final cuisine in listed) cuisine.code,
      if (listed.isEmpty) ...knownCuisines,
    ];
    final chosen = state.draft.cuisines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RiseIn(
          index: 0,
          child: StepIntro(
            title: l10n.onbCuisineTitle,
            subtitle: l10n.onbCuisineSubtitle,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < codes.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RiseIn(
              index: i + 1,
              child: ChoiceCard(
                key: Key('onb-cuisine-${codes[i]}'),
                emoji: cuisineEmoji(codes[i]),
                title: cuisineLabel(l10n, codes[i]),
                subtitle: cuisineHint(l10n, codes[i]),
                selected: chosen.contains(codes[i]),
                onTap: () => notifier.toggleCuisine(codes[i]),
              ),
            ),
          ),
        const SizedBox(height: 2),
        TipBanner(emoji: 'light-bulb', text: l10n.onbCuisineTip),
      ],
    );
  }
}

/// The cuisines of catalog_v3, for when the reference list is not loaded.
const knownCuisines = <String>['LIBYAN', 'LEVANTINE', 'EGYPTIAN', 'GENERAL'];

String cuisineEmoji(String code) {
  return switch (code) {
    'LIBYAN' => 'shallow-pan-of-food',
    'LEVANTINE' => 'stuffed-flatbread',
    'EGYPTIAN' => 'falafel',
    'GENERAL' => 'world-map',
    _ => 'fork-and-knife-with-plate',
  };
}

String cuisineLabel(AppLocalizations l10n, String code) {
  return switch (code) {
    'LIBYAN' => l10n.cuisineLibyan,
    'LEVANTINE' => l10n.cuisineLevantine,
    'EGYPTIAN' => l10n.cuisineEgyptian,
    'GENERAL' => l10n.cuisineGeneral,
    _ => code,
  };
}

String? cuisineHint(AppLocalizations l10n, String code) {
  return switch (code) {
    'LIBYAN' => l10n.cuisineLibyanHint,
    'LEVANTINE' => l10n.cuisineLevantineHint,
    'EGYPTIAN' => l10n.cuisineEgyptianHint,
    'GENERAL' => l10n.cuisineGeneralHint,
    _ => null,
  };
}
