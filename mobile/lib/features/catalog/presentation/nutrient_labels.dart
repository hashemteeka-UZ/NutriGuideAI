import '../../../core/l10n/app_localizations.dart';

String allergenLabel(AppLocalizations l10n, String code) {
  return switch (code) {
    'GLUTEN' => l10n.allergenGluten,
    'MILK' => l10n.allergenMilk,
    'EGG' => l10n.allergenEgg,
    'FISH' => l10n.allergenFish,
    'PEANUT' => l10n.allergenPeanut,
    'TREE_NUTS' => l10n.allergenTreeNuts,
    'SESAME' => l10n.allergenSesame,
    'SOY' => l10n.allergenSoy,
    _ => code,
  };
}

String nutrientLabel(AppLocalizations l10n, String code) {
  return switch (code) {
    'energy_kcal' => l10n.nutrientEnergy,
    'protein' => l10n.nutrientProtein,
    'carbohydrate' => l10n.nutrientCarbs,
    'total_fat' => l10n.nutrientFat,
    'fiber' => l10n.nutrientFiber,
    'sugars' => l10n.nutrientSugars,
    'saturated_fat' => l10n.nutrientSaturatedFat,
    'cholesterol' => l10n.nutrientCholesterol,
    'sodium' => l10n.nutrientSodium,
    'potassium' => l10n.nutrientPotassium,
    _ => code,
  };
}

String unitLabel(AppLocalizations l10n, String unit) {
  return switch (unit) {
    'g' => l10n.onbGrams,
    'mg' => l10n.mealMg,
    'kcal' => l10n.mealMacroKcal,
    _ => unit,
  };
}
