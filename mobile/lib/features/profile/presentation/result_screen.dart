import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../../core/ui/emoji.dart';
import '../domain/profile_result.dart';
import 'format_number.dart';
import 'how_calculated_sheet.dart';
import 'onboarding_controller.dart';

class ResultView extends ConsumerWidget {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(onboardingControllerProvider).result;
    if (result == null) {
      return const SizedBox.shrink();
    }
    if (!result.showPersonalPlan) {
      return _GeneralResult(result: result);
    }
    return _PersonalResult(result: result);
  }
}

class _PersonalResult extends ConsumerWidget {
  const _PersonalResult({required this.result});

  final ProfileResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final target = result.target!;
    final fellBack = ref.watch(onboardingControllerProvider).timezoneFellBack;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.onbResultTitle,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _CalorieHero(result: result),
        const SizedBox(height: 12),
        _MacroList(target: target),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                emoji: 'leafy-green',
                label: l10n.onbFiber,
                value:
                    '${formatMeasure(context, target.fiberG)} ${l10n.onbGrams}',
                color: context.appColors.fiber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                emoji: 'droplet',
                label: l10n.onbWater,
                value: _waterText(context, l10n, result.water),
                color: context.appColors.water,
              ),
            ),
          ],
        ),
        if (fellBack) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            l10n.onbTimezoneNote,
            key: const Key('onb-timezone-note'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: const Key('onb-how'),
            onPressed: () {
              showHowCalculated(
                context,
                target: target,
                goalType: result.goalType,
              );
            },
            child: Text(l10n.onbHowTitle),
          ),
        ),
      ],
    );
  }
}

class _CalorieHero extends StatefulWidget {
  const _CalorieHero({required this.result});

  final ProfileResult result;

  @override
  State<_CalorieHero> createState() => _CalorieHeroState();
}

class _CalorieHeroState extends State<_CalorieHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!animationsEnabled(context)) {
      _controller.value = 1;
      return;
    }
    if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final target = widget.result.target!;
    final line = switch (widget.result.goalType) {
      'LOSE' => l10n.onbLineLose,
      'GAIN' => l10n.onbLineGain,
      _ => l10n.onbLineMaintain,
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: colors.heroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              return CustomPaint(
                painter: _RingPainter(progress: _controller.value),
                child: SizedBox(width: 116, height: 116, child: child),
              );
            },
            child: const Center(child: Emoji('party-popper', size: 36)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.onbDailyCalories,
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  formatCount(context, target.kcal),
                  key: const Key('onb-kcal'),
                  style: colors.numeric.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(line, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 11.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0x38FFFFFF);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    canvas.drawArc(arc, 0, math.pi * 2, false, track);
    canvas.drawArc(arc, -math.pi / 2, math.pi * 2 * progress, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MacroList extends StatelessWidget {
  const _MacroList({required this.target});

  final DailyTarget target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = <Widget>[
      _MacroCard(
        emoji: 'poultry-leg',
        label: l10n.onbProtein,
        grams: target.proteinG,
        kcalEach: 4,
        color: context.appColors.protein,
        target: target,
      ),
      _MacroCard(
        emoji: 'bread',
        label: l10n.onbCarbs,
        grams: target.carbG,
        kcalEach: 4,
        color: context.appColors.carb,
        target: target,
      ),
      _MacroCard(
        emoji: 'avocado',
        label: l10n.onbFat,
        grams: target.fatG,
        kcalEach: 9,
        color: context.appColors.fat,
        target: target,
      ),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final row = constraints.maxWidth >= 480 && scale <= 1.15;
        if (!row) {
          return Column(
            children: <Widget>[
              for (final card in cards) ...<Widget>[
                card,
                const SizedBox(height: 8),
              ],
            ],
          );
        }
        return Row(
          children: <Widget>[
            for (var i = 0; i < cards.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class _MacroCard extends StatefulWidget {
  const _MacroCard({
    required this.emoji,
    required this.label,
    required this.grams,
    required this.kcalEach,
    required this.color,
    required this.target,
  });

  final String emoji;
  final String label;
  final num grams;
  final int kcalEach;
  final Color color;
  final DailyTarget target;

  @override
  State<_MacroCard> createState() => _MacroCardState();
}

class _MacroCardState extends State<_MacroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!animationsEnabled(context)) {
      _controller.value = 1;
      return;
    }
    if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final share = widget.target.kcal == 0
        ? 0.0
        : (widget.grams * widget.kcalEach / widget.target.kcal)
              .clamp(0, 1)
              .toDouble();
    final percent = (share * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          widget.color.withValues(alpha: 0.12),
          colors.surface,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Emoji(widget.emoji, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.label, style: TextStyle(color: colors.fg2)),
              ),
              Text(
                '${formatMeasure(context, widget.grams)} ${l10n.onbGrams}',
                style: colors.numeric.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(l10n.onbMacroShare('${formatCount(context, percent)}%')),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  return FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: share * _controller.value,
                    child: ColoredBox(color: widget.color),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  final String emoji;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.12), colors.surface),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Emoji(emoji, size: 24),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: colors.fg2)),
          Text(
            value,
            style: colors.numeric.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralResult extends StatelessWidget {
  const _GeneralResult({required this.result});

  final ProfileResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final reasons = <String>{
      for (final reason in result.reasons) _reason(l10n, reason),
    };
    if (reasons.isEmpty) {
      reasons.add(l10n.onbReasonGeneric);
    }
    final actions = <(String, String)>[
      ('fork-and-knife-with-plate', l10n.onbCanMeals),
      ('clipboard', l10n.onbCanLog),
      ('chart-increasing', l10n.onbCanProgress),
      ('shopping-cart', l10n.onbCanShop),
    ];
    return Column(
      key: const Key('onb-general'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Center(child: Emoji('seedling', size: 88)),
        const SizedBox(height: 12),
        Text(
          l10n.onbGeneralTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final reason in reasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              reason,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: colors.fg2, height: 1.4),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          l10n.onbCanDo,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: <Widget>[
                Emoji(action.$1, size: 26),
                const SizedBox(width: 10),
                Expanded(child: Text(action.$2)),
              ],
            ),
          ),
      ],
    );
  }
}

String _reason(AppLocalizations l10n, String reason) {
  if (reason == 'UNDER_18') {
    return l10n.onbReasonUnder18;
  }
  if (reason == 'UNSUPPORTED_CONDITION:DIABETES_INSULIN') {
    return l10n.onbReasonInsulin;
  }
  return l10n.onbReasonGeneric;
}

String _waterText(
  BuildContext context,
  AppLocalizations l10n,
  WaterView water,
) {
  if (water.clinicianWithoutGoal) {
    return l10n.onbWaterClinician;
  }
  final ml = water.goalMl;
  if (ml == null) {
    return l10n.onbWaterNone;
  }
  return '${formatCount(context, ml)} ${l10n.onbMl}';
}
