import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/emoji.dart';
import '../data/catalog_providers.dart';
import '../data/meal_pref_writer.dart';
import '../domain/meal.dart';

final mealFavouritesProvider = FutureProvider.autoDispose<MealFavourites>((
  ref,
) {
  ref.watch(mealRevisionProvider);
  return ref.watch(catalogRepositoryProvider).favourites();
});

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final favourites = ref.watch(mealFavouritesProvider);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.fg,
        title: Text(l10n.mealFavouritesTitle),
      ),
      body: favourites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            Center(child: Text(l10n.mealPrefSaveFailed)),
        data: (MealFavourites data) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              Text(
                l10n.mealFavouritesTitle,
                key: const Key('favourites-like-title'),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                l10n.mealFavouritesHint,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.fg2),
              ),
              const SizedBox(height: 8),
              if (data.liked.isEmpty)
                Text(
                  l10n.mealFavouritesEmpty,
                  key: const Key('favourites-like-empty'),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.fg3),
                )
              else
                for (final meal in data.liked)
                  _row(context, ref, meal, section: 'like'),
              const SizedBox(height: 20),
              Text(
                l10n.mealDislikesTitle,
                key: const Key('favourites-dislike-title'),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                l10n.mealDislikesHint,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.fg2),
              ),
              const SizedBox(height: 8),
              if (data.disliked.isEmpty)
                Text(
                  l10n.mealDislikesEmpty,
                  key: const Key('favourites-dislike-empty'),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.fg3),
                )
              else
                for (final meal in data.disliked)
                  _row(context, ref, meal, section: 'dislike'),
            ],
          );
        },
      ),
    );
  }
}

Widget _row(
  BuildContext context,
  WidgetRef ref,
  MealSummary meal, {
  required String section,
}) {
  final l10n = AppLocalizations.of(context);
  final colors = context.appColors;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: <Widget>[
        Emoji(meal.iconName, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            meal.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          key: Key('favourites-remove-$section-${meal.mealId}'),
          tooltip: l10n.mealRemove,
          onPressed: () {
            unawaited(_remove(context, ref, meal.mealId));
          },
          icon: Icon(Icons.close, color: colors.fg2),
        ),
      ],
    ),
  );
}

Future<void> _remove(BuildContext context, WidgetRef ref, int mealId) async {
  try {
    await ref.read(mealPrefWriterProvider).apply(mealId: mealId, stance: null);
  } on Object {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).mealPrefSaveFailed)),
    );
  }
}
