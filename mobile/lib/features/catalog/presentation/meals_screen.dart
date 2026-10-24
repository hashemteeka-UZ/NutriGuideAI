import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../data/meal_pref_writer.dart';
import '../domain/meal.dart';
import 'format_amount.dart';
import 'meal_card.dart';
import 'meals_controller.dart';

class MealsScreen extends ConsumerStatefulWidget {
  const MealsScreen({super.key});

  @override
  ConsumerState<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends ConsumerState<MealsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final state = ref.watch(mealsControllerProvider);
    final page = state.page;
    final offline = page != null && page.status == null;
    final noResults = page != null && page.status != null && page.meals.isEmpty;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.fg,
        title: Text(l10n.browseMeals),
        actions: <Widget>[
          IconButton(
            key: const Key('meal-open-favourites'),
            tooltip: l10n.mealFavouritesTitle,
            onPressed: () => context.push('/meals/favourites'),
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const Key('meals-search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.mealSearchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.line),
                ),
              ),
              onChanged: (String value) {
                ref.read(mealsControllerProvider.notifier).setSearch(value);
              },
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                _slot(context, null, l10n.mealSlotAll, state.query.occasionTag),
                _slot(
                  context,
                  breakfastTag,
                  l10n.mealSlotBreakfast,
                  state.query.occasionTag,
                ),
                _slot(
                  context,
                  lunchTag,
                  l10n.mealSlotLunch,
                  state.query.occasionTag,
                ),
                _slot(
                  context,
                  dinnerTag,
                  l10n.mealSlotDinner,
                  state.query.occasionTag,
                ),
                _slot(
                  context,
                  snackTag,
                  l10n.mealSlotSnack,
                  state.query.occasionTag,
                ),
                for (final cuisine in page?.cuisines ?? const <CuisineOption>[])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      key: Key('meals-cuisine-${cuisine.code}'),
                      label: Text(cuisine.name),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      selected: state.query.cuisineCode == cuisine.code,
                      onSelected: (bool selected) {
                        ref
                            .read(mealsControllerProvider.notifier)
                            .setCuisine(selected ? cuisine.code : null);
                      },
                    ),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            key: const Key('meals-hide-allergens'),
            value: state.query.hideAvoided,
            onChanged: (bool value) {
              ref.read(mealsControllerProvider.notifier).setHideAvoided(value);
            },
            title: Text(l10n.mealHideAvoided),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                return ref.read(mealsControllerProvider.notifier).refresh();
              },
              child: _body(
                context,
                state: state,
                offline: offline,
                noResults: noResults,
              ),
            ),
          ),
          if (page?.status != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                l10n.mealFooter(
                  page!.status!.mealCount,
                  formatUpdated(context, page.status!.fetchedAt),
                ),
                key: const Key('meals-footer'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.fg3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _slot(
    BuildContext context,
    String? tag,
    String label,
    String? selected,
  ) {
    final key = tag ?? 'all';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        key: Key('meals-slot-$key'),
        label: Text(label),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        selected: selected == tag,
        onSelected: (_) {
          ref.read(mealsControllerProvider.notifier).setOccasion(tag);
        },
      ),
    );
  }

  Widget _body(
    BuildContext context, {
    required MealsState state,
    required bool offline,
    required bool noResults,
  }) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    if (state.loading && state.page == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (offline) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                Text(
                  l10n.mealOfflineEmpty,
                  key: const Key('meals-offline-empty'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: colors.fg),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('meals-retry'),
                  onPressed: () {
                    unawaited(
                      ref.read(mealsControllerProvider.notifier).refresh(),
                    );
                  },
                  child: Text(l10n.mealRetry),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (noResults) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                Text(
                  l10n.mealNoResults,
                  key: const Key('meals-no-results'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: colors.fg),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('meals-clear-filters'),
                  onPressed: () {
                    _search.clear();
                    ref.read(mealsControllerProvider.notifier).clearFilters();
                  },
                  child: Text(l10n.mealClearFilters),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final meals = state.page?.meals ?? const <MealSummary>[];
    return ListView.builder(
      key: const Key('meals-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: meals.length,
      itemBuilder: (BuildContext context, int index) {
        final meal = meals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MealCard(
            meal: meal,
            onOpen: () => context.push('/meals/${meal.mealId}'),
            onHeart: () {
              unawaited(_heart(meal.mealId, liked: meal.liked));
            },
          ),
        );
      },
    );
  }

  Future<void> _heart(int mealId, {required bool liked}) async {
    try {
      await ref
          .read(mealPrefWriterProvider)
          .apply(mealId: mealId, stance: liked ? null : 'LIKE');
    } on Object {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).mealPrefSaveFailed),
        ),
      );
    }
  }
}
