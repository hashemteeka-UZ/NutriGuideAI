import 'meal.dart';

abstract interface class CatalogRepository {
  Future<MealBrowsePage> browse(MealQuery query);

  Future<MealDetail?> detail(int mealId);

  Future<MealFavourites> favourites();
}
