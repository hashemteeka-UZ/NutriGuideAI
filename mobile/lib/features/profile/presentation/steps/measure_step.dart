import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/rise_in.dart';
import '../../../weight/presentation/weight_sheet.dart';
import '../../domain/bmi.dart';
import '../format_number.dart';
import '../onboarding_controller.dart';
import '../widgets/choice_card.dart';
import '../widgets/wheel_picker.dart';

class MeasureStep extends ConsumerWidget {
  const MeasureStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final onboarding = ref.watch(onboardingControllerProvider);
    final draft = onboarding.draft;
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final bmi = bmiValue(heightCm: draft.heightCm, weightKg: draft.weightKg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RiseIn(
          index: 0,
          child: StepIntro(
            title: l10n.onbMeasureTitle,
            subtitle: l10n.onbMeasureSubtitle,
          ),
        ),
        const SizedBox(height: 12),
        RiseIn(
          index: 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _LabeledWheel(
                  label: l10n.onbHeight,
                  unit: l10n.onbCm,
                  child: NumberWheel(
                    min: 100,
                    max: 250,
                    step: 1,
                    value: draft.heightCm,
                    semanticLabel: l10n.onbHeight,
                    onChanged: notifier.setHeight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Editing a profile: weight has its own sheet (#309).
              if (onboarding.editing)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      key: const Key('edit-weight-hint'),
                      children: <Widget>[
                        Text(l10n.editWeightHint, textAlign: TextAlign.center),
                        TextButton(
                          key: const Key('edit-weight-open'),
                          onPressed: () => unawaited(showWeightSheet(context)),
                          child: Text(l10n.weightTitle),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: _LabeledWheel(
                    label: l10n.onbWeight,
                    unit: l10n.onbKg,
                    child: NumberWheel(
                      min: 20,
                      max: 400,
                      step: 0.5,
                      fractionDigits: 1,
                      value: draft.weightKg,
                      semanticLabel: l10n.onbWeight,
                      onChanged: notifier.setWeight,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RiseIn(index: 2, child: _BmiCard(bmi: bmi)),
        ExplainTile(
          title: l10n.onbBmiExplainTitle,
          body: l10n.onbBmiExplainBody,
        ),
      ],
    );
  }
}

class _LabeledWheel extends StatelessWidget {
  const _LabeledWheel({
    required this.label,
    required this.unit,
    required this.child,
  });

  final String label;
  final String unit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: <Widget>[
        Text(
          '$label ($unit)',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: colors.fg2, fontWeight: FontWeight.w700),
        ),
        child,
      ],
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.bmi});

  final double bmi;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final band = bmiBand(bmi);
    final (label, color) = switch (band) {
      BmiBand.under => (l10n.onbBmiUnder, colors.carb),
      BmiBand.normal => (l10n.onbBmiNormal, colors.ok),
      BmiBand.over => (l10n.onbBmiOver, colors.part),
      BmiBand.high => (l10n.onbBmiHigh, colors.warn),
    };
    return Container(
      key: const Key('onb-bmi'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                formatMeasure(context, bmi),
                key: const Key('onb-bmi-value'),
                style: colors.numeric.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: colors.fg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.onbBmi,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.fg2),
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    key: const Key('onb-bmi-label'),
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: _BmiScale(marker: bmiMarker(bmi), color: color),
          ),
        ],
      ),
    );
  }
}

class _BmiScale extends StatelessWidget {
  const _BmiScale({required this.marker, required this.color});

  final double marker;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 20,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final left = (constraints.maxWidth - 20) * marker;
              return Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        gradient: LinearGradient(
                          colors: <Color>[
                            colors.carb,
                            colors.carb,
                            colors.ok,
                            colors.ok,
                            colors.part,
                            colors.part,
                            colors.warn,
                            colors.warn,
                          ],
                          stops: const <double>[
                            0,
                            0.14,
                            0.14,
                            0.40,
                            0.40,
                            0.60,
                            0.60,
                            1,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surface,
                        border: Border.all(color: color, width: 4),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (final tick in const <num>[15, 18.5, 25, 30, 40])
              Text(
                formatMeasure(context, tick),
                style: colors.numeric.copyWith(fontSize: 11, color: colors.fg3),
              ),
          ],
        ),
      ],
    );
  }
}
