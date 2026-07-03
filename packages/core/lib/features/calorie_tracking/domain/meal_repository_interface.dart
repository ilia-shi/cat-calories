import 'package:cat_calories_core/features/profile/domain/profile.dart';

import './meal.dart';

abstract interface class MealRepositoryInterface {
  Future<List<Meal>> findAll();
  Future<List<Meal>> fetchByProfile(Profile profile);
  Future<Meal?> find(String id);
  Future<Meal> insert(Meal meal);
  Future<Meal> update(Meal meal);
  Future<int> delete(Meal meal);
}
