import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:test/test.dart';

void main() {
  CalorieRecord record({
    DateTime? eatenAt,
    DateTime? plannedFor,
    required DateTime createdAt,
  }) {
    return CalorieRecord(
      id: 'r1',
      value: 300,
      description: null,
      sortOrder: 0,
      eatenAt: eatenAt,
      createdAt: createdAt,
      profileId: 'p1',
      wakingPeriodId: null,
      plannedFor: plannedFor,
    );
  }

  final wednesday = DateTime(2026, 7, 8, 19, 30);
  final saturday = DateTime(2026, 7, 11);
  final sunday = DateTime(2026, 7, 12, 13, 5);

  group('recordDay', () {
    test('an ordinary record belongs to the day it was entered', () {
      expect(recordDay(record(createdAt: wednesday)), DateTime(2026, 7, 8));
    });

    test('a planned record belongs to the day it is planned for', () {
      final day = recordDay(
        record(createdAt: wednesday, plannedFor: saturday),
      );

      expect(day, DateTime(2026, 7, 11),
          reason: 'entered on Wednesday, but it is Saturday\'s dinner');
    });

    test('an eaten record belongs to the day it was eaten', () {
      final day = recordDay(
        record(createdAt: wednesday, plannedFor: saturday, eatenAt: sunday),
      );

      expect(day, DateTime(2026, 7, 12),
          reason: 'planned for Saturday, actually eaten on Sunday');
    });

    test('strips the time of day', () {
      expect(recordDay(record(createdAt: wednesday)).hour, 0);
      expect(recordDay(record(createdAt: wednesday)).minute, 0);
    });
  });

  group('mealDay', () {
    Meal meal({DateTime? plannedFor, DateTime? eatenAt}) => Meal(
          id: 'm1',
          profileId: 'p1',
          title: 'Curry',
          createdAt: wednesday,
          plannedFor: plannedFor,
          eatenAt: eatenAt,
        );

    test('a dayless meal belongs to the day it was created', () {
      expect(mealDay(meal()), DateTime(2026, 7, 8));
    });

    test('a planned meal belongs to the day it is planned for', () {
      expect(mealDay(meal(plannedFor: saturday)), DateTime(2026, 7, 11));
    });

    test('an eaten meal belongs to the day it was eaten', () {
      expect(
        mealDay(meal(plannedFor: saturday, eatenAt: sunday)),
        DateTime(2026, 7, 12),
      );
    });
  });

  group('the stored record_day key', () {
    int keyFor(CalorieRecord record) => record.toJson()['record_day'] as int;

    int keyOfDay(DateTime day) =>
        (DateTime(day.year, day.month, day.day).millisecondsSinceEpoch / 100000)
            .round();

    test('matches recordDay, so SQL and Dart bucket a record alike', () {
      final planned = record(createdAt: wednesday, plannedFor: saturday);
      final eaten = record(
        createdAt: wednesday,
        plannedFor: saturday,
        eatenAt: sunday,
      );
      final plain = record(createdAt: wednesday);

      expect(keyFor(planned), keyOfDay(recordDay(planned)));
      expect(keyFor(eaten), keyOfDay(recordDay(eaten)));
      expect(keyFor(plain), keyOfDay(recordDay(plain)));
    });

    test('follows the planned day away from the day it was entered', () {
      expect(
        keyFor(record(createdAt: wednesday, plannedFor: saturday)),
        keyOfDay(saturday),
      );
      expect(
        keyFor(record(createdAt: wednesday, plannedFor: saturday)),
        isNot(keyOfDay(wednesday)),
      );
    });
  });

  group('dayOf', () {
    test('keeps the calendar day and drops the clock', () {
      expect(dayOf(DateTime(2026, 7, 8, 23, 59, 59)), DateTime(2026, 7, 8));
    });
  });
}
