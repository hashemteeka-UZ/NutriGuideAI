import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/emoji.dart';
import '../../../../core/ui/rise_in.dart';
import '../onboarding_controller.dart';
import '../widgets/choice_card.dart';

class FluidStep extends ConsumerStatefulWidget {
  const FluidStep({super.key});

  @override
  ConsumerState<FluidStep> createState() => _FluidStepState();
}

class _FluidStepState extends ConsumerState<FluidStep> {
  late final TextEditingController _ml;

  @override
  void initState() {
    super.initState();
    final current = ref.read(onboardingControllerProvider).draft.waterGoalMl;
    _ml = TextEditingController(text: current?.toString() ?? '');
  }

  @override
  void dispose() {
    _ml.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(onboardingControllerProvider).draft;
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final colors = context.appColors;
    final invalid =
        draft.doctorSetWater == true &&
        (draft.waterGoalMl == null ||
            draft.waterGoalMl! < 500 ||
            draft.waterGoalMl! > 5000);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RiseIn(
          index: 0,
          child: StepIntro(
            title: l10n.onbFluidTitle,
            subtitle: l10n.onbFluidSubtitle,
            badge: '${l10n.onbJustForYou} · ${l10n.onbBecauseHeart}',
          ),
        ),
        const SizedBox(height: 12),
        const Center(child: Emoji('droplet', size: 64)),
        const SizedBox(height: 12),
        ChoiceCard(
          key: const Key('onb-fluid-none'),
          emoji: 'potable-water',
          title: l10n.onbFluidNone,
          subtitle: l10n.onbFluidNoneBody,
          selected: draft.doctorSetWater == false,
          onTap: () => notifier.setDoctorWater(false),
        ),
        const SizedBox(height: 10),
        ChoiceCard(
          key: const Key('onb-fluid-doctor'),
          emoji: 'stethoscope',
          title: l10n.onbFluidDoctor,
          selected: draft.doctorSetWater == true,
          onTap: () {
            notifier.setDoctorWater(true);
            final parsed = int.tryParse(_ml.text);
            if (parsed != null) {
              notifier.setWaterGoal(parsed);
            }
          },
        ),
        if (draft.doctorSetWater == true) ...<Widget>[
          const SizedBox(height: 12),
          TextField(
            key: const Key('onb-fluid-ml'),
            controller: _ml,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              suffixText: l10n.onbMl,
              errorText: invalid && _ml.text.isNotEmpty
                  ? l10n.onbFluidRange
                  : null,
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onChanged: (String value) {
              notifier.setWaterGoal(int.tryParse(value));
            },
          ),
        ],
      ],
    );
  }
}
