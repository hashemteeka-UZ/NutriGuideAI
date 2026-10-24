class MealSummary {
  const MealSummary({
    required this.mealId,
    required this.name,
    required this.kcal,
    required this.proteinG,
    required this.cuisineCode,
    required this.cuisineName,
    required this.tags,
    required this.iconName,
    required this.liked,
    required this.allergenWarning,
  });

  final int mealId;
  final String name;
  final double kcal;
  final double proteinG;
  final String? cuisineCode;
  final String? cuisineName;
  final List<String> tags;
  final String iconName;
  final bool liked;
  final bool allergenWarning;
}

class IngredientLine {
  const IngredientLine({
    required this.name,
    required this.gramsPerServing,
    required this.isOptional,
  });

  final String name;
  final double gramsPerServing;
  final bool isOptional;
}

class NutrientLine {
  const NutrientLine({
    required this.code,
    required this.unit,
    required this.perServing,
    required this.per100g,
  });

  final String code;
  final String unit;
  final double? perServing;
  final double? per100g;
}

class MealDetail {
  const MealDetail({
    required this.mealId,
    required this.name,
    required this.cuisineName,
    required this.servingGrams,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.sodiumPerServing,
    required this.saturatedFatPerServing,
    required this.nutrients,
    required this.ingredients,
    required this.steps,
    required this.iconName,
    required this.stance,
    required this.warningAllergenCodes,
  });

  final int mealId;
  final String name;
  final String? cuisineName;
  final double servingGrams;
  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final double? sodiumPerServing;
  final double? saturatedFatPerServing;
  final List<NutrientLine> nutrients;
  final List<IngredientLine> ingredients;
  final List<String> steps;
  final String iconName;

  /// `LIKE`, `DISLIKE`, or null when the user has no stance.
  final String? stance;
  final List<String> warningAllergenCodes;
}

class CuisineOption {
  const CuisineOption({required this.code, required this.name});

  final String code;
  final String name;
}

class CatalogStatus {
  const CatalogStatus({required this.mealCount, required this.fetchedAt});

  final int mealCount;
  final DateTime fetchedAt;
}

class MealQuery {
  const MealQuery({
    this.text = '',
    this.occasionTag,
    this.cuisineCode,
    this.hideAvoided = true,
  });

  final String text;
  final String? occasionTag;
  final String? cuisineCode;
  final bool hideAvoided;

  MealQuery copyWith({
    String? text,
    Object? occasionTag = _keep,
    Object? cuisineCode = _keep,
    bool? hideAvoided,
  }) {
    return MealQuery(
      text: text ?? this.text,
      occasionTag: identical(occasionTag, _keep)
          ? this.occasionTag
          : occasionTag as String?,
      cuisineCode: identical(cuisineCode, _keep)
          ? this.cuisineCode
          : cuisineCode as String?,
      hideAvoided: hideAvoided ?? this.hideAvoided,
    );
  }
}

const _keep = Object();

class MealBrowsePage {
  const MealBrowsePage({
    required this.meals,
    required this.cuisines,
    required this.status,
  });

  final List<MealSummary> meals;
  final List<CuisineOption> cuisines;
  final CatalogStatus? status;
}

class MealFavourites {
  const MealFavourites({required this.liked, required this.disliked});

  final List<MealSummary> liked;
  final List<MealSummary> disliked;
}

const knownNutrientCodes = <String>[
  'energy_kcal',
  'protein',
  'carbohydrate',
  'total_fat',
  'fiber',
  'sugars',
  'saturated_fat',
  'cholesterol',
  'sodium',
  'potassium',
];

const breakfastTag = 'breakfast_suitable';
const lunchTag = 'lunch_suitable';
const dinnerTag = 'dinner_suitable';
const snackTag = 'snack_suitable';

String iconForOccasionTags(Iterable<String> tagsInOrder) {
  for (final tag in tagsInOrder) {
    switch (tag) {
      case breakfastTag:
        return 'sunrise';
      case lunchTag:
        return 'sun';
      case dinnerTag:
        return 'crescent-moon';
      case snackTag:
        return 'red-apple';
    }
  }
  return 'fork-and-knife';
}
