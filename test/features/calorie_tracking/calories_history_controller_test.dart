import 'package:cat_calories/app/profile_resolver.dart';
import 'package:cat_calories/features/calorie_tracking/ui/state/calories_history_controller.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/color_label.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_repository_interface.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fakes: implement only the methods the controller touches; everything else
/// falls through [noSuchMethod] (and throws if unexpectedly called).
class _FakeRecordRepo implements CalorieRecordRepositoryInterface {
  final List<CalorieRecord> records;
  final List<CalorieRecord> updated = [];
  final List<CalorieRecord> inserted = [];
  final List<CalorieRecord> deleted = [];

  _FakeRecordRepo(this.records);

  @override
  Future<List<CalorieRecord>> fetchAllByProfile(
    Profile profile, {
    String orderBy = '',
    int? limit,
    int? offset,
  }) async {
    // Mimic the DB `created_at DESC` the controller requests.
    return [...records]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<CalorieRecord> update(CalorieRecord record) async {
    updated.add(record);
    return record;
  }

  @override
  Future<CalorieRecord> insert(CalorieRecord record) async {
    record.id ??= 'rec-${inserted.length}';
    inserted.add(record);
    records.add(record);
    return record;
  }

  @override
  Future<int> delete(CalorieRecord record) async {
    deleted.add(record);
    records.remove(record);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMealRepo implements MealRepositoryInterface {
  final List<Meal> meals;
  final List<Meal> inserted = [];
  final List<Meal> deleted = [];
  int _seq = 0;

  _FakeMealRepo(this.meals);

  @override
  Future<List<Meal>> fetchByProfile(Profile profile) async => [...meals];

  @override
  Future<Meal> insert(Meal meal) async {
    meal.id ??= 'meal-${_seq++}';
    inserted.add(meal);
    meals.add(meal);
    return meal;
  }

  @override
  Future<Meal> update(Meal meal) async => meal;

  @override
  Future<int> delete(Meal meal) async {
    deleted.add(meal);
    meals.remove(meal);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileResolver extends ProfileResolver {
  final Profile _profile;

  _FakeProfileResolver(this._profile);

  @override
  Future<Profile> resolve() async => _profile;
}

void main() {
  final profile = Profile(
    id: 'p1',
    name: 'Test',
    wakingTimeSeconds: 16 * 60 * 60,
    caloriesLimitGoal: 2000,
    createdAt: DateTime(2020),
    updatedAt: DateTime(2020),
  );

  // The parent ProfileResolver's field initializer calls
  // SharedPreferences.getInstance() when the fake is constructed.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  CalorieRecord record({
    required String id,
    required DateTime createdAt,
    required double value,
    bool eaten = true,
    double? protein,
    double? fat,
    double? carbs,
    String? mealId,
    DateTime? plannedFor,
  }) {
    return CalorieRecord(
      id: id,
      value: value,
      description: null,
      sortOrder: 0,
      eatenAt: eaten ? createdAt : null,
      createdAt: createdAt,
      profileId: profile.id!,
      wakingPeriodId: null,
      proteinGrams: protein,
      fatGrams: fat,
      carbGrams: carbs,
      mealId: mealId,
      plannedFor: plannedFor,
    );
  }

  CaloriesHistoryController controllerWith(
    List<CalorieRecord> records, {
    List<Meal> meals = const [],
  }) {
    return CaloriesHistoryController(
      recordRepository: _FakeRecordRepo(records),
      mealRepository: _FakeMealRepo([...meals]),
      profileResolver: _FakeProfileResolver(profile),
    );
  }

  // Two distinct calendar days; day A (Jul 4) is newer than day B (Jul 3).
  final dayAmorning = DateTime(2026, 7, 4, 8, 30);
  final dayAnoon = DateTime(2026, 7, 4, 12, 0);
  final dayB = DateTime(2026, 7, 3, 9, 0);
  final dayAkey = DateTime(2026, 7, 4);
  final dayBkey = DateTime(2026, 7, 3);

  group('load / grouping', () {
    test('buckets records by calendar day, newest day first', () async {
      final controller = controllerWith([
        record(id: 'a1', createdAt: dayAmorning, value: 500),
        record(id: 'a2', createdAt: dayAnoon, value: 300),
        record(id: 'b1', createdAt: dayB, value: 200),
      ]);

      await controller.load();

      expect(controller.sortedDates, [dayAkey, dayBkey]);
      expect(controller.groupedCalories[dayAkey]!.length, 2);
      expect(controller.groupedCalories[dayBkey]!.length, 1);
    });

    test('counts every record but only sums eaten ones', () async {
      final controller = controllerWith([
        record(id: 'a1', createdAt: dayAmorning, value: 500),
        record(id: 'a2', createdAt: dayAnoon, value: 300, eaten: false),
      ]);

      await controller.load();

      final summary = controller.daySummaries[dayAkey]!;
      expect(summary.itemCount, 2, reason: 'planned record still counts');
      expect(summary.totalEaten, 500, reason: 'planned record not summed');
      expect(summary.positiveSum, 500);
      expect(summary.negativeSum, 0);
    });

    test('splits positive and negative eaten values', () async {
      final controller = controllerWith([
        record(id: 'a1', createdAt: dayAmorning, value: 500),
        record(id: 'a2', createdAt: dayAnoon, value: -200),
      ]);

      await controller.load();

      final summary = controller.daySummaries[dayAkey]!;
      expect(summary.totalEaten, 300);
      expect(summary.positiveSum, 500);
      expect(summary.negativeSum, -200);
    });

    test('aggregates macros only for eaten records that have them', () async {
      final controller = controllerWith([
        record(id: 'a1', createdAt: dayAmorning, value: 500, protein: 10, fat: 5),
        record(id: 'a2', createdAt: dayAnoon, value: 300, protein: 20),
        // planned record with macros must be ignored
        record(id: 'a3', createdAt: dayAnoon, value: 100, eaten: false, protein: 99),
      ]);

      await controller.load();

      final summary = controller.daySummaries[dayAkey]!;
      expect(summary.totalProtein, 30);
      expect(summary.totalFat, 5);
      expect(summary.hasProteinData, isTrue);
      expect(summary.hasFatData, isTrue);
      expect(summary.hasCarbData, isFalse);
    });

    test('computes all-time totals across days', () async {
      final controller = controllerWith([
        record(id: 'a1', createdAt: dayAmorning, value: 500, protein: 10),
        record(id: 'a2', createdAt: dayAnoon, value: 300, eaten: false),
        record(id: 'b1', createdAt: dayB, value: -200, protein: 5),
      ]);

      await controller.load();

      expect(controller.totalItems, 3);
      expect(controller.totalAllTime, 300); // 500 - 200, planned excluded
      expect(controller.totalProtein, 15);
    });

    test('indexes meals by id, skipping meals without an id', () async {
      final withId = Meal(
        id: 'm1',
        profileId: profile.id!,
        title: 'Lunch',
        createdAt: dayAmorning,
      );
      final withoutId = Meal(
        id: null,
        profileId: profile.id!,
        title: 'Ghost',
        createdAt: dayAmorning,
      );
      final controller = controllerWith(
        [record(id: 'a1', createdAt: dayAmorning, value: 100)],
        meals: [withId, withoutId],
      );

      await controller.load();

      expect(controller.mealsById.keys, ['m1']);
      expect(controller.mealsById['m1']!.title, 'Lunch');
    });

    test('expands only the newest day on the initial load', () async {
      final controller = controllerWith([
        record(id: 'a1', createdAt: dayAmorning, value: 500),
        record(id: 'b1', createdAt: dayB, value: 200),
      ]);

      await controller.load();

      expect(controller.isExpanded(dayAkey), isTrue);
      expect(controller.isExpanded(dayBkey), isFalse);
    });

    test('does not re-expand the newest day on a later reload', () async {
      final controller = controllerWith([
        record(id: 'a1', createdAt: dayAmorning, value: 500),
      ]);

      await controller.load();
      controller.collapseAll();
      await controller.load();

      expect(controller.isExpanded(dayAkey), isFalse);
    });

    test('surfaces load errors once via takeError', () async {
      final controller = CaloriesHistoryController(
        recordRepository: _ThrowingRecordRepo(),
        mealRepository: _FakeMealRepo([]),
        profileResolver: _FakeProfileResolver(profile),
      );

      await controller.load();

      expect(controller.isLoading, isFalse);
      final error = controller.takeError();
      expect(error, contains('Error loading calories'));
      expect(controller.takeError(), isNull, reason: 'error is one-shot');
    });
  });

  group('selection', () {
    test('toggles ids on and off', () async {
      final controller = controllerWith([
        record(id: 'a1', createdAt: dayAmorning, value: 500),
      ]);
      await controller.load();
      final item = controller.groupedCalories[dayAkey]!.first;

      expect(controller.hasSelection, isFalse);
      controller.toggleSelection(item);
      expect(controller.hasSelection, isTrue);
      expect(controller.selectionCount, 1);
      expect(controller.isSelected('a1'), isTrue);

      controller.toggleSelection(item);
      expect(controller.hasSelection, isFalse);
    });

    test('clearSelection empties the selection', () async {
      final controller = controllerWith([
        record(id: 'a1', createdAt: dayAmorning, value: 500),
      ]);
      await controller.load();
      controller.toggleSelection(controller.groupedCalories[dayAkey]!.first);

      controller.clearSelection();

      expect(controller.hasSelection, isFalse);
    });
  });

  group('groupSelectedAsMeal', () {
    test('creates a meal, assigns it to the selected records, clears '
        'selection', () async {
      final records = [
        record(id: 'a1', createdAt: dayAmorning, value: 500),
        record(id: 'a2', createdAt: dayAnoon, value: 300),
      ];
      final controller = controllerWith(records);
      await controller.load();
      for (final r in [...controller.groupedCalories[dayAkey]!]) {
        controller.toggleSelection(r);
      }

      final meal = await controller.groupSelectedAsMeal('Lunch');

      expect(meal, isNotNull);
      expect(meal!.title, 'Lunch');
      expect(records.every((r) => r.mealId == meal.id), isTrue);
      expect(controller.hasSelection, isFalse);
    });

    test('returns null when nothing is selected', () async {
      final controller = controllerWith([
        record(id: 'a1', createdAt: dayAmorning, value: 500),
      ]);
      await controller.load();

      expect(await controller.groupSelectedAsMeal('X'), isNull);
    });
  });

  group('mealCandidatesFor', () {
    Meal meal(String id, {DateTime? createdAt}) => Meal(
          id: id,
          profileId: profile.id!,
          title: 'Meal $id',
          createdAt: createdAt ?? dayAmorning,
        );

    test('offers meals with a member that day, and empty ones', () async {
      final controller = controllerWith(
        [
          record(id: 'a1', createdAt: dayAmorning, value: 100, mealId: 'same'),
          record(id: 'b1', createdAt: dayB, value: 100, mealId: 'other'),
          record(id: 'a2', createdAt: dayAnoon, value: 100),
        ],
        meals: [meal('same'), meal('other'), meal('empty')],
      );
      await controller.load();

      final ids = controller
          .mealCandidatesFor(dayAnoon)
          .map((m) => m.id)
          .toList();

      expect(ids, containsAll(['same', 'empty']));
      expect(ids, isNot(contains('other')),
          reason: 'its only member is on another day — the block would split');
    });

    test('sorts same-day meals before empty ones, newest first', () async {
      final controller = controllerWith(
        [
          record(id: 'a1', createdAt: dayAmorning, value: 100, mealId: 'old'),
          record(id: 'a2', createdAt: dayAnoon, value: 100, mealId: 'new'),
        ],
        meals: [
          meal('old', createdAt: dayAmorning),
          meal('new', createdAt: dayAnoon),
          meal('empty', createdAt: dayAnoon),
        ],
      );
      await controller.load();

      expect(
        controller.mealCandidatesFor(dayAnoon).map((m) => m.id),
        ['new', 'old', 'empty'],
      );
    });

    test('excludes the record own meal', () async {
      final controller = controllerWith(
        [record(id: 'a1', createdAt: dayAmorning, value: 100, mealId: 'mine')],
        meals: [meal('mine')],
      );
      await controller.load();

      expect(
        controller.mealCandidatesFor(dayAmorning, excludeMealId: 'mine'),
        isEmpty,
      );
    });
  });

  group('moveToMeal', () {
    Meal meal(String id) => Meal(
          id: id,
          profileId: profile.id!,
          title: 'Meal $id',
          createdAt: dayAmorning,
        );

    test('assigns the target meal and persists the record', () async {
      final item = record(id: 'a1', createdAt: dayAmorning, value: 100);
      final repo = _FakeRecordRepo([
        item,
        record(id: 'a2', createdAt: dayAnoon, value: 200, mealId: 'target'),
      ]);
      final controller = CaloriesHistoryController(
        recordRepository: repo,
        mealRepository: _FakeMealRepo([meal('target')]),
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      final emptied = await controller.moveToMeal(
        item,
        controller.mealsById['target']!,
      );

      expect(item.mealId, 'target');
      expect(repo.updated, [item]);
      expect(emptied, isNull);
    });

    test('deletes the source meal when the record was its last member',
        () async {
      final item = record(
        id: 'a1',
        createdAt: dayAmorning,
        value: 100,
        mealId: 'source',
      );
      final mealRepo = _FakeMealRepo([meal('source'), meal('target')]);
      final controller = CaloriesHistoryController(
        recordRepository: _FakeRecordRepo([
          item,
          record(id: 'a2', createdAt: dayAnoon, value: 200, mealId: 'target'),
        ]),
        mealRepository: mealRepo,
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      final emptied = await controller.moveToMeal(
        item,
        controller.mealsById['target']!,
      );

      expect(emptied?.id, 'source');
      expect(mealRepo.deleted.map((m) => m.id), ['source']);
    });

    test('keeps a source meal that still has members', () async {
      final item = record(
        id: 'a1',
        createdAt: dayAmorning,
        value: 100,
        mealId: 'source',
      );
      final mealRepo = _FakeMealRepo([meal('source'), meal('target')]);
      final controller = CaloriesHistoryController(
        recordRepository: _FakeRecordRepo([
          item,
          record(id: 'a2', createdAt: dayAnoon, value: 50, mealId: 'source'),
        ]),
        mealRepository: mealRepo,
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      final emptied = await controller.moveToMeal(
        item,
        controller.mealsById['target']!,
      );

      expect(emptied, isNull);
      expect(mealRepo.deleted, isEmpty);
    });

    test('does nothing when the record is already in the target', () async {
      final item = record(
        id: 'a1',
        createdAt: dayAmorning,
        value: 100,
        mealId: 'target',
      );
      final repo = _FakeRecordRepo([item]);
      final controller = CaloriesHistoryController(
        recordRepository: repo,
        mealRepository: _FakeMealRepo([meal('target')]),
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      await controller.moveToMeal(item, controller.mealsById['target']!);

      expect(repo.updated, isEmpty);
    });

    test('bumps updatedAt so the move syncs', () async {
      final item = record(id: 'a1', createdAt: dayAmorning, value: 100);
      final before = item.updatedAt;
      final controller = controllerWith([item], meals: [meal('target')]);
      await controller.load();

      await controller.moveToMeal(item, controller.mealsById['target']!);

      expect(item.updatedAt.isAfter(before), isTrue);
    });
  });

  group('deleteMeal', () {
    test('deletes every member record and the meal itself', () async {
      final members = [
        record(id: 'a1', createdAt: dayAmorning, value: 100, mealId: 'm1'),
        record(id: 'a2', createdAt: dayAnoon, value: 200, mealId: 'm1'),
      ];
      final other = record(id: 'b1', createdAt: dayB, value: 300);
      final recordRepo = _FakeRecordRepo([...members, other]);
      final meal = Meal(
        id: 'm1',
        profileId: profile.id!,
        title: 'Lunch',
        createdAt: dayAmorning,
      );
      final mealRepo = _FakeMealRepo([meal]);
      final controller = CaloriesHistoryController(
        recordRepository: recordRepo,
        mealRepository: mealRepo,
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      await controller.deleteMeal(meal, members);

      expect(recordRepo.deleted.map((r) => r.id), ['a1', 'a2']);
      expect(mealRepo.deleted, [meal]);
      expect(controller.mealsById, isEmpty);
      expect(controller.membersByMeal, isEmpty);
      expect(controller.sortedDates, [dayBkey],
          reason: 'day A had only the deleted meal records');
      expect(controller.totalAllTime, 300);
    });

    test('deletes the meal even when it has no records', () async {
      final meal = Meal(
        id: 'm1',
        profileId: profile.id!,
        title: 'Planned',
        createdAt: dayAmorning,
      );
      final recordRepo = _FakeRecordRepo([
        record(id: 'a1', createdAt: dayAmorning, value: 100),
      ]);
      final mealRepo = _FakeMealRepo([meal]);
      final controller = CaloriesHistoryController(
        recordRepository: recordRepo,
        mealRepository: mealRepo,
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      await controller.deleteMeal(meal, const []);

      expect(recordRepo.deleted, isEmpty);
      expect(mealRepo.deleted, [meal]);
      expect(controller.totalAllTime, 100);
    });
  });

  group('setColorLabel', () {
    test('persists the chosen color and clearing it again', () async {
      final item = record(id: 'a1', createdAt: dayAmorning, value: 500);
      final repo = _FakeRecordRepo([item]);
      final controller = CaloriesHistoryController(
        recordRepository: repo,
        mealRepository: _FakeMealRepo([]),
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      await controller.setColorLabel(item, ColorLabelPreset.blue.color);
      expect(item.colorLabel, ColorLabelPreset.blue.color);
      expect(repo.updated, [item]);

      await controller.setColorLabel(item, null);
      expect(item.colorLabel, isNull);
      expect(repo.updated, [item, item]);
    });

    test('bumps updatedAt so the change syncs', () async {
      final item = record(id: 'a1', createdAt: dayAmorning, value: 500);
      final before = item.updatedAt;
      final controller = controllerWith([item]);
      await controller.load();

      await controller.setColorLabel(item, ColorLabelPreset.orange.color);

      expect(item.updatedAt.isAfter(before), isTrue);
    });
  });

  group('grouping by the day a record belongs to', () {
    final saturday = DateTime(2026, 7, 11);
    final sunday = DateTime(2026, 7, 12);

    Meal plannedMeal(String id, {DateTime? plannedFor, DateTime? createdAt}) =>
        Meal(
          id: id,
          profileId: profile.id!,
          title: 'Curry',
          createdAt: createdAt ?? dayAmorning,
          plannedFor: plannedFor,
        );

    test('a planned record files under the day it is planned for', () async {
      final controller = controllerWith([
        record(id: 'a1', createdAt: dayAmorning, value: 500),
        record(
          id: 'p1',
          createdAt: dayAmorning,
          value: 700,
          eaten: false,
          plannedFor: saturday,
        ),
      ]);

      await controller.load();

      expect(controller.sortedDates, [saturday, dayAkey],
          reason: 'the planned day is in the future, so it sorts first');
      expect(controller.groupedCalories[saturday]!.map((r) => r.id), ['p1']);
      expect(controller.groupedCalories[dayAkey]!.map((r) => r.id), ['a1']);
    });

    test('an eaten record files under the day it was eaten, not planned',
        () async {
      final item = record(id: 'a1', createdAt: dayAmorning, value: 500,
          eaten: false, plannedFor: saturday);
      item.eatenAt = sunday;
      final controller = controllerWith([item]);

      await controller.load();

      expect(controller.sortedDates, [sunday]);
      expect(controller.daySummaries[sunday]!.totalEaten, 500);
    });

    test('planned calories are summarised apart from eaten ones', () async {
      final controller = controllerWith([
        record(id: 'a1', createdAt: dayAmorning, value: 500),
        record(id: 'a2', createdAt: dayAnoon, value: 300, eaten: false),
      ]);

      await controller.load();

      final summary = controller.daySummaries[dayAkey]!;
      expect(summary.totalEaten, 500);
      expect(summary.plannedKcal, 300);
      expect(summary.plannedItemCount, 1);
      expect(summary.showsPlannedTotal, isFalse,
          reason: 'the day has eaten calories to lead with');
    });

    test('a day with only a plan leads with the planned figure', () async {
      final controller = controllerWith([
        record(
          id: 'p1',
          createdAt: dayAmorning,
          value: 700,
          eaten: false,
          plannedFor: saturday,
        ),
      ]);

      await controller.load();

      final summary = controller.daySummaries[saturday]!;
      expect(summary.totalEaten, 0);
      expect(summary.plannedKcal, 700);
      expect(summary.showsPlannedTotal, isTrue);
    });

    test('a meal with no records still gets a day of its own', () async {
      final controller = controllerWith(
        [record(id: 'a1', createdAt: dayAmorning, value: 500)],
        meals: [plannedMeal('m1', plannedFor: saturday)],
      );

      await controller.load();

      expect(controller.sortedDates, [saturday, dayAkey]);
      expect(controller.emptyMealsOn(saturday).map((m) => m.id), ['m1']);
      expect(controller.emptyMealsOn(dayAkey), isEmpty);
    });

    test('an empty meal with no day falls back to the day it was made',
        () async {
      final controller = controllerWith(
        const [],
        meals: [plannedMeal('m1', createdAt: dayAmorning)],
      );

      await controller.load();

      expect(controller.sortedDates, [dayAkey]);
      expect(controller.emptyMealsOn(dayAkey).map((m) => m.id), ['m1']);
    });

    test('a meal that has records is placed by them, not listed as empty',
        () async {
      final controller = controllerWith(
        [
          record(
            id: 'a1',
            createdAt: dayAmorning,
            value: 500,
            eaten: false,
            mealId: 'm1',
            plannedFor: saturday,
          ),
        ],
        meals: [plannedMeal('m1', plannedFor: saturday)],
      );

      await controller.load();

      expect(controller.emptyMealsOn(saturday), isEmpty);
      expect(controller.membersByMeal['m1']!.map((r) => r.id), ['a1']);
    });

    test('the first load opens today, never a day still to come', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextWeek = DateTime(now.year, now.month, now.day + 7);
      final controller = controllerWith([
        record(id: 'a1', createdAt: today.add(const Duration(hours: 9)),
            value: 500),
        record(
          id: 'p1',
          createdAt: today.add(const Duration(hours: 10)),
          value: 700,
          eaten: false,
          plannedFor: nextWeek,
        ),
      ]);

      await controller.load();

      expect(controller.sortedDates.first, nextWeek);
      expect(controller.isExpanded(today), isTrue);
      expect(controller.isExpanded(nextWeek), isFalse);
    });

    test('with only future days the first load opens the nearest one',
        () async {
      final now = DateTime.now();
      final nextWeek = DateTime(now.year, now.month, now.day + 7);
      final fortnight = DateTime(now.year, now.month, now.day + 14);
      final controller = controllerWith([
        record(id: 'p1', createdAt: now, value: 700, eaten: false,
            plannedFor: nextWeek),
        record(id: 'p2', createdAt: now, value: 800, eaten: false,
            plannedFor: fortnight),
      ]);

      await controller.load();

      expect(controller.isExpanded(nextWeek), isTrue);
      expect(controller.isExpanded(fortnight), isFalse);
    });
  });

  group('planned day', () {
    final saturday = DateTime(2026, 7, 11);
    final sunday = DateTime(2026, 7, 12);

    test('createNewMeal stores the day it was planned for', () async {
      final mealRepo = _FakeMealRepo([]);
      final controller = CaloriesHistoryController(
        recordRepository: _FakeRecordRepo([]),
        mealRepository: mealRepo,
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      final meal = await controller.createNewMeal('Curry',
          plannedFor: saturday);

      expect(meal.plannedFor, saturday);
      expect(mealRepo.inserted.single.plannedFor, saturday);
    });

    test('createNewMeal leaves the day empty when none was chosen', () async {
      final controller = controllerWith([]);
      await controller.load();

      final meal = await controller.createNewMeal('Curry');

      expect(meal.plannedFor, isNull);
    });

    test('duplicateMeal stamps its day and title on the copies', () async {
      final source = Meal(
        id: 'm1',
        profileId: profile.id!,
        title: 'Old curry',
        createdAt: dayAmorning,
        plannedFor: saturday,
      );
      final members = [
        record(id: 'a1', createdAt: dayAmorning, value: 300, mealId: 'm1'),
        record(id: 'a2', createdAt: dayAnoon, value: 200, mealId: 'm1'),
      ];
      final recordRepo = _FakeRecordRepo([...members]);
      final controller = CaloriesHistoryController(
        recordRepository: recordRepo,
        mealRepository: _FakeMealRepo([source]),
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      final copy = await controller.duplicateMeal(
        source,
        members,
        title: 'Curry again',
        plannedFor: sunday,
      );

      expect(copy.title, 'Curry again');
      expect(copy.plannedFor, sunday);
      expect(recordRepo.inserted.length, 2);
      expect(
        recordRepo.inserted.every((r) => r.plannedFor == sunday),
        isTrue,
        reason: 'a copy belongs to the day its new meal is planned for',
      );
      expect(
        recordRepo.inserted.every((r) => r.mealId == copy.id && !r.isEaten()),
        isTrue,
      );
    });

    test('duplicateMeal falls back to the source title', () async {
      final source = Meal(
        id: 'm1',
        profileId: profile.id!,
        title: 'Old curry',
        createdAt: dayAmorning,
      );
      final controller = CaloriesHistoryController(
        recordRepository: _FakeRecordRepo([]),
        mealRepository: _FakeMealRepo([source]),
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      final copy = await controller.duplicateMeal(source, const []);

      expect(copy.title, 'Old curry');
      expect(copy.plannedFor, isNull);
    });

    test('saveMeal moves the members onto the meal\'s new day', () async {
      final meal = Meal(
        id: 'm1',
        profileId: profile.id!,
        title: 'Curry',
        createdAt: dayAmorning,
        plannedFor: saturday,
      );
      final members = [
        record(
          id: 'a1',
          createdAt: dayAmorning,
          value: 300,
          eaten: false,
          mealId: 'm1',
          plannedFor: saturday,
        ),
        record(
          id: 'a2',
          createdAt: dayAnoon,
          value: 200,
          eaten: false,
          mealId: 'm1',
          plannedFor: saturday,
        ),
      ];
      final recordRepo = _FakeRecordRepo([...members]);
      final controller = CaloriesHistoryController(
        recordRepository: recordRepo,
        mealRepository: _FakeMealRepo([meal]),
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      meal.plannedFor = sunday;
      await controller.saveMeal(meal);

      expect(members.every((r) => r.plannedFor == sunday), isTrue);
      expect(recordRepo.updated.map((r) => r.id).toSet(), {'a1', 'a2'});
    });

    test('saveMeal writes no record whose day already matches', () async {
      final meal = Meal(
        id: 'm1',
        profileId: profile.id!,
        title: 'Curry',
        createdAt: dayAmorning,
        plannedFor: saturday,
      );
      final recordRepo = _FakeRecordRepo([
        record(
          id: 'a1',
          createdAt: dayAmorning,
          value: 300,
          eaten: false,
          mealId: 'm1',
          plannedFor: saturday,
        ),
      ]);
      final controller = CaloriesHistoryController(
        recordRepository: recordRepo,
        mealRepository: _FakeMealRepo([meal]),
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      meal.title = 'Curry, renamed';
      await controller.saveMeal(meal);

      expect(recordRepo.updated, isEmpty,
          reason: 'a rename must not bump updatedAt on every ingredient');
    });

    test('moveToMeal puts the record on the target meal\'s day', () async {
      final item = record(
        id: 'a1',
        createdAt: dayAmorning,
        value: 100,
        eaten: false,
        mealId: 'source',
      );
      final controller = CaloriesHistoryController(
        recordRepository: _FakeRecordRepo([
          item,
          record(id: 'a2', createdAt: dayAmorning, value: 50, mealId: 'source'),
          record(id: 'a3', createdAt: dayAnoon, value: 200, mealId: 'target'),
        ]),
        mealRepository: _FakeMealRepo([
          Meal(
            id: 'source',
            profileId: profile.id!,
            title: 'Source',
            createdAt: dayAmorning,
          ),
          Meal(
            id: 'target',
            profileId: profile.id!,
            title: 'Target',
            createdAt: dayAmorning,
            plannedFor: sunday,
          ),
        ]),
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      await controller.moveToMeal(item, controller.mealsById['target']!);

      expect(item.plannedFor, sunday);
    });

    test('groupSelectedAsMeal adopts a day all the records share', () async {
      final records = [
        record(
          id: 'a1',
          createdAt: dayAmorning,
          value: 500,
          eaten: false,
          plannedFor: saturday,
        ),
        record(
          id: 'a2',
          createdAt: dayAnoon,
          value: 300,
          eaten: false,
          plannedFor: saturday,
        ),
      ];
      final controller = controllerWith(records);
      await controller.load();
      // Selected across days: a planned record now groups under the day it is
      // planned for, not the day it was entered.
      for (final r
          in controller.groupedCalories.values.expand((day) => day).toList()) {
        controller.toggleSelection(r);
      }

      final meal = await controller.groupSelectedAsMeal('Lunch');

      expect(meal!.plannedFor, saturday);
      expect(records.every((r) => r.plannedFor == saturday), isTrue);
    });

    test('emptying a planned meal keeps it — the plan was deliberate',
        () async {
      final item = record(
        id: 'a1',
        createdAt: dayAmorning,
        value: 100,
        eaten: false,
        mealId: 'source',
        plannedFor: saturday,
      );
      final mealRepo = _FakeMealRepo([
        Meal(
          id: 'source',
          profileId: profile.id!,
          title: 'Curry',
          createdAt: dayAmorning,
          plannedFor: saturday,
        ),
      ]);
      final controller = CaloriesHistoryController(
        recordRepository: _FakeRecordRepo([item]),
        mealRepository: mealRepo,
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      await controller.removeFromMeal(item);

      expect(mealRepo.deleted, isEmpty);
      expect(
        controller.emptyMealsOn(saturday).map((m) => m.id),
        ['source'],
        reason: 'it now renders empty on its own day instead of vanishing',
      );
    });

    test('emptying a meal with no planned day still removes it', () async {
      final item = record(
        id: 'a1',
        createdAt: dayAmorning,
        value: 100,
        mealId: 'source',
      );
      final mealRepo = _FakeMealRepo([
        Meal(
          id: 'source',
          profileId: profile.id!,
          title: 'Leftover group',
          createdAt: dayAmorning,
        ),
      ]);
      final controller = CaloriesHistoryController(
        recordRepository: _FakeRecordRepo([item]),
        mealRepository: mealRepo,
        profileResolver: _FakeProfileResolver(profile),
      );
      await controller.load();

      await controller.removeFromMeal(item);

      expect(mealRepo.deleted.map((m) => m.id), ['source']);
    });

    test('groupSelectedAsMeal stays dayless when the records disagree',
        () async {
      final records = [
        record(
          id: 'a1',
          createdAt: dayAmorning,
          value: 500,
          eaten: false,
          plannedFor: saturday,
        ),
        record(
          id: 'a2',
          createdAt: dayAnoon,
          value: 300,
          eaten: false,
          plannedFor: sunday,
        ),
      ];
      final controller = controllerWith(records);
      await controller.load();
      // Selected across days: a planned record now groups under the day it is
      // planned for, not the day it was entered.
      for (final r
          in controller.groupedCalories.values.expand((day) => day).toList()) {
        controller.toggleSelection(r);
      }

      final meal = await controller.groupSelectedAsMeal('Lunch');

      expect(meal!.plannedFor, isNull);
      expect(
        records.every((r) => r.plannedFor == null),
        isTrue,
        reason: 'members follow the meal, so the group cannot span two days',
      );
    });
  });
}

class _ThrowingRecordRepo implements CalorieRecordRepositoryInterface {
  @override
  Future<List<CalorieRecord>> fetchAllByProfile(
    Profile profile, {
    String orderBy = '',
    int? limit,
    int? offset,
  }) async {
    throw StateError('boom');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
