import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/emoji.dart';
import '../domain/meal.dart';
import 'format_amount.dart';

class MealCard extends StatelessWidget {
  const MealCard({
    required this.meal,
    required this.onOpen,
    required this.onHeart,
    super.key,
  });

  final MealSummary meal;
  final VoidCallback onOpen;
  final VoidCallback onHeart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final kcal = formatAmount(context, meal.kcal);
    final protein = formatAmount(context, meal.proteinG);
    final label = <String>[
      meal.name,
      l10n.mealKcal(kcal),
      if (meal.liked) l10n.mealFavourite,
      if (meal.allergenWarning) l10n.mealAllergenBadge,
    ].join(', ');
    return Semantics(
      container: true,
      button: true,
      label: label,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: Key('meal-card-${meal.mealId}'),
          onTap: onOpen,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.line),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Emoji(meal.iconName, size: 36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        meal.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.fg,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.mealKcal(kcal)} · ${l10n.mealProtein(protein)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.fg2),
                      ),
                      if (meal.cuisineName != null)
                        Text(
                          meal.cuisineName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.fg3),
                        ),
                      if (meal.allergenWarning)
                        Text(
                          l10n.mealAllergenBadge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.danger),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('meal-heart-${meal.mealId}'),
                  tooltip: l10n.mealFavourite,
                  onPressed: onHeart,
                  icon: Icon(
                    meal.liked ? Icons.favorite : Icons.favorite_border,
                    color: meal.liked ? colors.protein : colors.fg3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
