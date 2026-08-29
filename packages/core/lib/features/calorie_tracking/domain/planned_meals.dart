import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';

/// A meal with something still to eat on one particular day.
class PlannedMeal {
  final Meal meal;

  /// That day's members that are not eaten yet — what "mark it eaten" acts on.
  final List<CalorieRecord> records;

  const PlannedMeal({required this.meal, required this.records});
}

/// The meals still to be eaten on [day], newest plan last.
///
/// A meal qualifies on its records, not on its own [Meal.plannedFor]: an
/// ingredient counts for the day it belongs to, which for an uneaten one is the
/// day it is planned for. A meal with no ingredients yet is left out — there is
/// nothing to eat in it, so a one-tap "eaten" would stamp an empty dish.
List<PlannedMeal> plannedMealsOn(
  DateTime day, {
  required List<Meal> meals,
  required List<CalorieRecord> records,
}) {
  final target = dayOf(day);
  final uneatenByMeal = <String, List<CalorieRecord>>{};
  for (final record in records) {
    final mealId = record.mealId;
    if (mealId == null || record.isEaten() || recordDay(record) != target) {
      continue;
    }
    (uneatenByMeal[mealId] ??= <CalorieRecord>[]).add(record);
  }

  final planned = <PlannedMeal>[];
  for (final meal in meals) {
    final id = meal.id;
    if (id == null) {
      continue;
    }
    final members = uneatenByMeal[id];
    if (members == null || members.isEmpty) {
      continue;
    }
    planned.add(PlannedMeal(meal: meal, records: members));
  }

  planned.sort((a, b) => a.meal.createdAt.compareTo(b.meal.createdAt));
  return planned;
}
