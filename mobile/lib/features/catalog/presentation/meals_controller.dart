import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/locale_controller.dart';
import '../data/catalog_providers.dart';
import '../data/catalog_sync.dart';
import '../data/meal_pref_writer.dart';
import '../domain/meal.dart';

class MealsState {
  const MealsState({
    required this.query,
    required this.page,
    required this.loading,
  });

  static const initial = MealsState(
    query: MealQuery(),
    page: null,
    loading: true,
  );

  final MealQuery query;
  final MealBrowsePage? page;
  final bool loading;

  MealsState copyWith({MealQuery? query, MealBrowsePage? page, bool? loading}) {
    return MealsState(
      query: query ?? this.query,
      page: page ?? this.page,
      loading: loading ?? this.loading,
    );
  }
}

class MealsController extends Notifier<MealsState> {
  Timer? _debounce;

  @override
  MealsState build() {
    ref.onDispose(() => _debounce?.cancel());
    ref.listen(localeProvider, (Locale? previous, Locale next) {
      unawaited(reload());
    });
    ref.listen(mealRevisionProvider, (int? previous, int next) {
      unawaited(reload());
    });
    Future<void>.microtask(() {
      if (ref.mounted) {
        unawaited(reload());
      }
    });
    return MealsState.initial;
  }

  void setSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(query: state.query.copyWith(text: text));
      unawaited(reload());
    });
  }

  void setOccasion(String? tag) {
    state = state.copyWith(query: state.query.copyWith(occasionTag: tag));
    unawaited(reload());
  }

  void setCuisine(String? code) {
    state = state.copyWith(query: state.query.copyWith(cuisineCode: code));
    unawaited(reload());
  }

  void setHideAvoided(bool hide) {
    state = state.copyWith(query: state.query.copyWith(hideAvoided: hide));
    unawaited(reload());
  }

  void clearFilters() {
    _debounce?.cancel();
    state = const MealsState(query: MealQuery(), page: null, loading: true);
    unawaited(reload());
  }

  Future<void> refresh() async {
    await ref
        .read(catalogSyncProvider)
        .sync(lang: ref.read(localeProvider).languageCode);
    await reload();
  }

  Future<void> reload() async {
    final query = state.query;
    final page = await ref.read(catalogRepositoryProvider).browse(query);
    if (!ref.mounted || state.query != query) {
      return;
    }
    state = state.copyWith(page: page, loading: false);
  }
}

final mealsControllerProvider = NotifierProvider<MealsController, MealsState>(
  MealsController.new,
);
