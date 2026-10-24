import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/emoji.dart';
import '../../../../core/ui/rise_in.dart';
import '../onboarding_controller.dart';
import '../widgets/choice_card.dart';

class AllergyStep extends ConsumerWidget {
  const AllergyStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final sex = state.draft.sex ?? 'other';
    final allergens = state.reference?.allergens ?? const [];
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RiseIn(
          index: 0,
          child: StepIntro(
            title: l10n.onbAllergyTitle(sex),
            subtitle: l10n.onbAllergySubtitle(sex),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allergens.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 124 * scale.clamp(1, 1.45),
          ),
          itemBuilder: (BuildContext context, int index) {
            final allergen = allergens[index];
            final severity = state.draft.allergens[allergen.code];
            final emoji = allergenEmoji(allergen.code);
            return _AllergenTile(
              key: Key('onb-allergen-${allergen.code}'),
              emoji: emoji,
              iconKey: Key('allergen-icon-${allergen.code}-$emoji'),
              name: allergen.name,
              severity: severity,
              avoid: l10n.onbAvoid,
              severe: l10n.onbSevere,
              onTap: () => notifier.cycleAllergen(allergen.code),
            );
          },
        ),
        const SizedBox(height: 12),
        TipBanner(emoji: 'shield', text: l10n.onbAllergyTip),
      ],
    );
  }
}

class _AllergenTile extends StatelessWidget {
  const _AllergenTile({
    required this.emoji,
    required this.iconKey,
    required this.name,
    required this.severity,
    required this.avoid,
    required this.severe,
    required this.onTap,
    super.key,
  });

  final String emoji;
  final Key iconKey;
  final String name;
  final String? severity;
  final String avoid;
  final String severe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selected = severity != null;
    final severeSelected = severity == 'SEVERE';
    final badge = severeSelected ? severe : avoid;
    final label = selected ? '$name, $badge' : name;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? colors.brand : colors.line,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (selected)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: severeSelected ? colors.danger : colors.part,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Emoji(emoji, size: 36, key: iconKey),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String allergenEmoji(String code) {
  return switch (code) {
    'GLUTEN' => 'sheaf-of-rice',
    'MILK' => 'glass-of-milk',
    'EGG' => 'egg',
    'FISH' => 'fish',
    'PEANUT' => 'peanuts',
    'TREE_NUTS' => 'chestnut',
    'SESAME' => 'jar',
    'SOY' => 'beans',
    _ => 'fork-and-knife',
  };
}
