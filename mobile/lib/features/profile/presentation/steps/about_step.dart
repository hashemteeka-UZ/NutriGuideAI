import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/emoji.dart';
import '../../../../core/ui/rise_in.dart';
import '../../domain/clock_time.dart';
import '../../domain/profile_draft.dart';
import '../format_number.dart';
import '../onboarding_controller.dart';
import '../widgets/choice_card.dart';
import '../widgets/wheel_picker.dart';

class AboutStep extends ConsumerWidget {
  const AboutStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(onboardingControllerProvider).draft;
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final today = ref.watch(onboardingNowProvider)();
    final birth = draft.birthDate ?? defaultBirthDate(today);
    final age = formatCount(context, ageInYears(birth, today));
    final firstYear = today.year - 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RiseIn(
          index: 0,
          child: StepIntro(
            title: l10n.onbAboutTitle,
            subtitle: l10n.onbAboutSubtitle,
          ),
        ),
        const SizedBox(height: 18),
        RiseIn(
          index: 1,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _SexCard(
                  key: const Key('onb-sex-MALE'),
                  emoji: 'man',
                  label: l10n.onbSexMale,
                  selected: draft.sex == 'MALE',
                  onTap: () => notifier.selectSex('MALE'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SexCard(
                  key: const Key('onb-sex-FEMALE'),
                  emoji: 'woman',
                  label: l10n.onbSexFemale,
                  selected: draft.sex == 'FEMALE',
                  onTap: () => notifier.selectSex('FEMALE'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        RiseIn(
          index: 2,
          child: Text(
            l10n.onbAge(age),
            key: const Key('onb-age'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.appColors.fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        RiseIn(
          index: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: WheelPicker(
                  itemCount: daysInMonth(birth.year, birth.month),
                  selectedIndex: birth.day - 1,
                  semanticLabel: l10n.onbAge(age),
                  labelForIndex: (int index) => formatCount(context, index + 1),
                  onSelected: (int index) {
                    notifier.setBirthDate(
                      DateTime.utc(birth.year, birth.month, index + 1),
                    );
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: WheelPicker(
                  itemCount: 12,
                  selectedIndex: birth.month - 1,
                  semanticLabel: l10n.onbAge(age),
                  labelForIndex: (int index) {
                    return DateFormat.MMMM(localeNameOf(context))
                        .format(DateTime.utc(2020, index + 1, 1));
                  },
                  onSelected: (int index) {
                    notifier.setBirthDate(
                      DateTime.utc(birth.year, index + 1, birth.day),
                    );
                  },
                ),
              ),
              Expanded(
                child: WheelPicker(
                  itemCount: 101,
                  selectedIndex: birth.year - firstYear,
                  semanticLabel: l10n.onbAge(age),
                  labelForIndex: (int index) {
                    return formatCount(context, firstYear + index);
                  },
                  onSelected: (int index) {
                    notifier.setBirthDate(
                      DateTime.utc(firstYear + index, birth.month, birth.day),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SexCard extends StatelessWidget {
  const _SexCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final background = selected
        ? Color.alphaBlend(colors.brand.withValues(alpha: 0.10), colors.surface)
        : colors.surface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 132),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? colors.brand : colors.line,
                width: 1.5,
              ),
            ),
            child: Column(
              children: <Widget>[
                Emoji(emoji, size: 58),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
