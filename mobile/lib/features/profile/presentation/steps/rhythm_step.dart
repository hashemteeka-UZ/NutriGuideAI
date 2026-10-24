import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/emoji.dart';
import '../../../../core/ui/rise_in.dart';
import '../../domain/clock_time.dart';
import '../../domain/meal_windows.dart';
import '../onboarding_controller.dart';
import '../widgets/choice_card.dart';

class RhythmStep extends ConsumerWidget {
  const RhythmStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(onboardingControllerProvider).draft;
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final sex = draft.sex ?? 'other';
    final windows = suggestedMealWindows(
      wakeMinutes: draft.wakeMinutes,
      sleepMinutes: draft.sleepMinutes,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RiseIn(
          index: 0,
          child: StepIntro(
            title: l10n.onbRhythmTitle(sex),
            subtitle: l10n.onbRhythmSubtitle,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _ClockCard(
                emoji: 'sunrise',
                label: l10n.onbWake,
                minutes: draft.wakeMinutes,
                onMinus: () => notifier.shiftWake(-15),
                onPlus: () => notifier.shiftWake(15),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ClockCard(
                emoji: 'crescent-moon',
                label: l10n.onbSleep,
                minutes: draft.sleepMinutes,
                onMinus: () => notifier.shiftSleep(-15),
                onPlus: () => notifier.shiftSleep(15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l10n.onbSuggestedDay,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final window in windows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                Emoji(_slotEmoji(window.slot), size: 24),
                const SizedBox(width: 10),
                Expanded(child: Text(_slotLabel(l10n, window.slot))),
                Text(
                  l10n.onbWindow(
                    formatClock(window.startMinutes),
                    formatClock(window.endMinutes),
                  ),
                  style: context.appColors.numeric.copyWith(
                    color: context.appColors.fg2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ClockCard extends StatelessWidget {
  const _ClockCard({
    required this.emoji,
    required this.label,
    required this.minutes,
    required this.onMinus,
    required this.onPlus,
  });

  final String emoji;
  final String label;
  final int minutes;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: <Widget>[
          Emoji(emoji, size: 36),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _StepButton(icon: Icons.remove, onPressed: onMinus, label: '-15'),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  formatClock(minutes),
                  style: colors.numeric.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _StepButton(icon: Icons.add, onPressed: onPlus, label: '+15'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onPressed,
    required this.label,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    );
  }
}

String _slotEmoji(String slot) {
  return switch (slot) {
    'BREAKFAST' => 'sunrise',
    'LUNCH' => 'sun',
    'SNACK' => 'red-apple',
    _ => 'crescent-moon',
  };
}

String _slotLabel(AppLocalizations l10n, String slot) {
  return switch (slot) {
    'BREAKFAST' => l10n.onbBreakfast,
    'LUNCH' => l10n.onbLunch,
    'SNACK' => l10n.onbSnack,
    _ => l10n.onbDinner,
  };
}
