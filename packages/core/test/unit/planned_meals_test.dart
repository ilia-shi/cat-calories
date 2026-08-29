import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/planned_meals.dart';
import 'package:test/test.dart';

void main() {
  final today = DateTime(2026, 8, 29);
  final tomorrow = DateTime(2026, 8, 30);

  CalorieRecord record({
    required String id,
    String? mealId,
    DateTime? plannedFor,
    DateTime? eatenAt,
    DateTime? createdAt,
  }) {
    return CalorieRecord(
      id: id,
      value: 250,
      description: null,
      sortOrder: 0,
      eatenAt: eatenAt,
      createdAt: createdAt ?? DateTime(2026, 8, 27, 18),
      profileId: 'p1',
      wakingPeriodId: null,
      mealId: mealId,
      plannedFor: plannedFor,
    );
  }

  Meal meal(String id, {DateTime? createdAt, DateTime? plannedFor}) => Meal(
        id: id,
        profileId: 'p1',
        title: 'Meal $id',
        createdAt: createdAt ?? DateTime(2026, 8, 27, 12),
        plannedFor: plannedFor,
      );

  test('lists a meal whose ingredients are planned for the day', () {
    final planned = plannedMealsOn(
      today,
      meals: [meal('m1', plannedFor: today)],
      records: [
        record(id: 'a1', mealId: 'm1', plannedFor: today),
        record(id: 'a2', mealId: 'm1', plannedFor: today),
      ],
    );

    expect(planned.single.meal.id, 'm1');
    expect(planned.single.records.map((r) => r.id), ['a1', 'a2']);
  });

  test('ignores the time of day in the day asked for', () {
    final planned = plannedMealsOn(
      DateTime(2026, 8, 29, 22, 45),
      meals: [meal('m1', plannedFor: today)],
      records: [record(id: 'a1', mealId: 'm1', plannedFor: today)],
    );

    expect(planned, hasLength(1));
  });

  test('leaves out what is already eaten', () {
    final planned = plannedMealsOn(
      today,
      meals: [meal('m1', plannedFor: today)],
      records: [
        record(id: 'a1', mealId: 'm1', plannedFor: today),
        record(
          id: 'a2',
          mealId: 'm1',
          plannedFor: today,
          eatenAt: DateTime(2026, 8, 29, 13),
        ),
      ],
    );

    expect(planned.single.records.map((r) => r.id), ['a1'],
        reason: 'marking eaten acts on what is left, not the whole meal again');
  });

  test('a fully eaten meal drops off the day', () {
    final planned = plannedMealsOn(
      today,
      meals: [meal('m1', plannedFor: today)],
      records: [
        record(
          id: 'a1',
          mealId: 'm1',
          plannedFor: today,
          eatenAt: DateTime(2026, 8, 29, 13),
        ),
      ],
    );

    expect(planned, isEmpty);
  });

  test('another day\'s plan stays on its own day', () {
    final planned = plannedMealsOn(
      today,
      meals: [meal('m1', plannedFor: tomorrow)],
      records: [record(id: 'a1', mealId: 'm1', plannedFor: tomorrow)],
    );

    expect(planned, isEmpty);
  });

  test('a meal with no ingredients yet is not offered as eatable', () {
    final planned = plannedMealsOn(
      today,
      meals: [meal('m1', plannedFor: today)],
      records: const [],
    );

    expect(planned, isEmpty,
        reason: 'there is nothing in it to mark eaten');
  });

  test('ungrouped planned records belong to no meal and are skipped', () {
    final planned = plannedMealsOn(
      today,
      meals: [meal('m1', plannedFor: today)],
      records: [record(id: 'loose', plannedFor: today)],
    );

    expect(planned, isEmpty);
  });

  test('an uneaten record with no planned day counts on the day it was made',
      () {
    final planned = plannedMealsOn(
      today,
      meals: [meal('m1')],
      records: [
        record(id: 'a1', mealId: 'm1', createdAt: DateTime(2026, 8, 29, 9)),
      ],
    );

    expect(planned.single.records.map((r) => r.id), ['a1']);
  });

  test('meals come back in the order they were planned', () {
    final planned = plannedMealsOn(
      today,
      meals: [
        meal('later', createdAt: DateTime(2026, 8, 28, 20)),
        meal('earlier', createdAt: DateTime(2026, 8, 26, 8)),
      ],
      records: [
        record(id: 'a1', mealId: 'later', plannedFor: today),
        record(id: 'a2', mealId: 'earlier', plannedFor: today),
      ],
    );

    expect(planned.map((p) => p.meal.id), ['earlier', 'later']);
  });
}
