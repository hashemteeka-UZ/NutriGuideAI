import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'reason_labels.dart';

class ReasonChips extends StatelessWidget {
  const ReasonChips({
    required this.codes,
    required this.languageCode,
    required this.conditionNames,
    this.max = 2,
    super.key,
  });

  final List<String> codes;
  final String languageCode;
  final Map<String, String> conditionNames;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final chips = <Widget>[];
    for (final code in codes) {
      if (chips.length >= max) {
        break;
      }
      final condition = code.startsWith('SUITS_CONDITION_')
          ? conditionNames[code.substring('SUITS_CONDITION_'.length)]
          : null;
      final label = reasonLabel(
        code,
        languageCode: languageCode,
        conditionName: condition,
      );
      if (label == null) {
        continue;
      }
      chips.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 6, top: 6),
          child: Container(
            key: Key('reason-$code'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.brandSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(_icon(code), size: 14, color: colors.brand2),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: colors.fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(children: chips);
  }
}

IconData _icon(String code) {
  return switch (code) {
    'FITS_KCAL_TARGET' => Icons.local_fire_department_outlined,
    'HIGH_PROTEIN' => Icons.egg_alt_outlined,
    'LOW_SODIUM' => Icons.water_drop_outlined,
    'LOW_SUGAR' => Icons.cookie_outlined,
    'LOW_SATURATED_FAT' => Icons.opacity,
    'HIGH_FIBER' => Icons.grass_outlined,
    'MATCHES_LIKED_INGREDIENT' => Icons.favorite_border,
    'NEW_FOR_VARIETY' => Icons.auto_awesome_outlined,
    _ => Icons.health_and_safety_outlined,
  };
}
