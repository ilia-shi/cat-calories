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

      await controller.setColorLabel(item, ColorLabelPreset.cyan.color);
      expect(item.colorLabel, ColorLabelPreset.cyan.color);
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

      await controller.setColorLabel(item, ColorLabelPreset.brown.color);

      expect(item.updatedAt.isAfter(before), isTrue);
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
