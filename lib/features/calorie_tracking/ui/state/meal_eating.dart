import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_repository_interface.dart';

/// Marking a meal eaten, and taking it back, in the one place both the history
/// screen and the home screen's today-strip read it from — the two stamp the
/// same fields and must not drift apart.
///
/// Neither reloads anything: the caller owns whatever state has to be
/// refreshed afterwards.
class MealEating {
  final MealRepositoryInterface mealRepository;
  final CalorieRecordRepositoryInterface recordRepository;

  const MealEating({
    required this.mealRepository,
    required this.recordRepository,
  });

  /// Stamps the meal and every member that is not eaten yet, all at one moment.
  Future<void> markEaten(Meal meal, List<CalorieRecord> members) async {
    final now = DateTime.now();
    meal.eatenAt = now;
    meal.updatedAt = now;
    await mealRepository.update(meal);
    for (final record in members) {
      if (!record.isEaten()) {
        record.eatenAt = now;
        record.updatedAt = now;
        await recordRepository.update(record);
      }
    }
  }

  /// Back to planned: clears the stamp from the meal and every member holding
  /// one, which is what returns the meal to the day it is planned for.
  Future<void> markNotEaten(Meal meal, List<CalorieRecord> members) async {
    final now = DateTime.now();
    meal.eatenAt = null;
    meal.updatedAt = now;
    await mealRepository.update(meal);
    for (final record in members) {
      if (record.isEaten()) {
        record.eatenAt = null;
        record.updatedAt = now;
        await recordRepository.update(record);
      }
    }
  }
}
