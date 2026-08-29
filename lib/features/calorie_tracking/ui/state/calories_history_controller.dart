import 'package:cat_calories/app/profile_resolver.dart';
import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/day_summary.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/color_label.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/record_day.dart';
import 'package:flutter/foundation.dart';

/// Loads the full calorie history, groups it by day and performs the
/// meal-grouping mutations. Pure state + repository orchestration — it holds no
/// widgets and does no navigation, snackbars or bloc dispatch, so the grouping
/// logic can be exercised in a unit test. The screen listens for changes and
/// owns all the UI side effects.
class CaloriesHistoryController extends ChangeNotifier {
  CaloriesHistoryController({
    CalorieRecordRepositoryInterface? recordRepository,
    MealRepositoryInterface? mealRepository,
    ProfileResolver? profileResolver,
  })  : _recordRepository = recordRepository ??
            locator.get<CalorieRecordRepositoryInterface>(),
        _mealRepository =
            mealRepository ?? locator.get<MealRepositoryInterface>(),
        _profileResolver = profileResolver ?? ProfileResolver();

  final CalorieRecordRepositoryInterface _recordRepository;
  final MealRepositoryInterface _mealRepository;
  final ProfileResolver _profileResolver;

  bool _isLoading = true;
  bool _isInitialLoad = true;
  Map<String, Meal> _mealsById = {};
  Map<String, List<CalorieRecord>> _membersByMeal = {};
  Map<DateTime, List<Meal>> _emptyMealsByDay = {};
  Map<DateTime, List<CalorieRecord>> _groupedCalories = {};
  Map<DateTime, DaySummary> _daySummaries = {};
  List<DateTime> _sortedDates = [];
  final Set<DateTime> _expandedDates = {};
  final Set<String> _selectedIds = {};
  double _totalAllTime = 0;
  int _totalItems = 0;
  double _totalProtein = 0;
  double _totalFat = 0;
  double _totalCarbs = 0;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  Map<String, Meal> get mealsById => _mealsById;

  /// Every meal's records, keyed by meal id. Built with the day grouping so
  /// callers get a meal's stats without rescanning the whole history.
  Map<String, List<CalorieRecord>> get membersByMeal => _membersByMeal;

  /// Meals with no records at all, keyed by the day they are planned for (or
  /// were created on). They have no record to render them, so the screen adds
  /// their headers to the day itself.
  List<Meal> emptyMealsOn(DateTime date) =>
      _emptyMealsByDay[date] ?? const <Meal>[];

  Map<DateTime, List<CalorieRecord>> get groupedCalories => _groupedCalories;
  Map<DateTime, DaySummary> get daySummaries => _daySummaries;
  List<DateTime> get sortedDates => _sortedDates;
  double get totalAllTime => _totalAllTime;
  int get totalItems => _totalItems;
  double get totalProtein => _totalProtein;
  double get totalFat => _totalFat;
  double get totalCarbs => _totalCarbs;

  bool get hasSelection => _selectedIds.isNotEmpty;
  int get selectionCount => _selectedIds.length;
  bool isSelected(String? id) => id != null && _selectedIds.contains(id);
  bool isExpanded(DateTime date) => _expandedDates.contains(date);

  /// Returns the pending load-error message once, clearing it. The screen uses
  /// this to show the error snackbar exactly once per failure.
  String? takeError() {
    final error = _errorMessage;
    _errorMessage = null;
    return error;
  }

  Future<void> load({bool showLoading = false}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final profile = await _profileResolver.resolve();
      final records = await _recordRepository.fetchAllByProfile(
        profile,
        orderBy: 'created_at DESC',
      );
      final meals = await _mealRepository.fetchByProfile(profile);
      _regroup(records, meals);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading calories: $e';
      notifyListeners();
    }
  }

  void _regroup(List<CalorieRecord> records, List<Meal> meals) {
    final grouped = <DateTime, List<CalorieRecord>>{};
    final summaries = <DateTime, DaySummary>{};
    final membersByMeal = <String, List<CalorieRecord>>{};
    double total = 0;
    int itemCount = 0;
    double totalProtein = 0;
    double totalFat = 0;
    double totalCarbs = 0;

    for (final calorie in records) {
      final dateKey = recordDay(calorie);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
        summaries[dateKey] = DaySummary();
      }
      final summary = summaries[dateKey]!;
      grouped[dateKey]!.add(calorie);
      summary.itemCount++;
      itemCount++;

      final mealId = calorie.mealId;
      if (mealId != null) {
        (membersByMeal[mealId] ??= <CalorieRecord>[]).add(calorie);
      }

      if (!calorie.isEaten()) {
        summary.plannedKcal += calorie.value;
        summary.plannedItemCount++;
      }

      if (calorie.isEaten()) {
        total += calorie.value;
        summary.totalEaten += calorie.value;
        if (calorie.value > 0) {
          summary.positiveSum += calorie.value;
        } else {
          summary.negativeSum += calorie.value;
        }

        if (calorie.proteinGrams != null) {
          summary.totalProtein += calorie.proteinGrams!;
          totalProtein += calorie.proteinGrams!;
          summary.hasProteinData = true;
        }
        if (calorie.fatGrams != null) {
          summary.totalFat += calorie.fatGrams!;
          totalFat += calorie.fatGrams!;
          summary.hasFatData = true;
        }
        if (calorie.carbGrams != null) {
          summary.totalCarbs += calorie.carbGrams!;
          totalCarbs += calorie.carbGrams!;
          summary.hasCarbData = true;
        }
      }
    }

    // A meal holding no records reaches no day through a record, so it would
    // render nowhere at all — which is how a meal planned and then left empty
    // used to become unreachable. Give it a day of its own.
    final emptyMealsByDay = <DateTime, List<Meal>>{};
    for (final meal in meals) {
      final id = meal.id;
      if (id == null || (membersByMeal[id] ?? const []).isNotEmpty) {
        continue;
      }
      final dateKey = mealDay(meal);
      grouped.putIfAbsent(dateKey, () => []);
      summaries.putIfAbsent(dateKey, () => DaySummary());
      (emptyMealsByDay[dateKey] ??= <Meal>[]).add(meal);
    }
    for (final dayMeals in emptyMealsByDay.values) {
      dayMeals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    _mealsById = {
      for (final meal in meals)
        if (meal.id != null) meal.id!: meal,
    };
    _emptyMealsByDay = emptyMealsByDay;
    _membersByMeal = membersByMeal;
    _groupedCalories = grouped;
    _daySummaries = summaries;
    _sortedDates = sortedDates;
    _totalAllTime = total;
    _totalItems = itemCount;
    _totalProtein = totalProtein;
    _totalFat = totalFat;
    _totalCarbs = totalCarbs;

    // Expand one date by default on the very first load: today, or failing
    // that the most recent day already past. Never a day still to come — the
    // list is newest first, so planned days sit above today and would
    // otherwise be the one opened.
    if (_isInitialLoad && sortedDates.isNotEmpty) {
      final today = dayOf(DateTime.now());
      _expandedDates.add(sortedDates.firstWhere(
        (date) => !date.isAfter(today),
        orElse: () => sortedDates.last,
      ));
      _isInitialLoad = false;
    }
  }

  // --- Selection -----------------------------------------------------------

  void toggleSelection(CalorieRecord item) {
    final id = item.id;
    if (id == null) {
      return;
    }
    if (!_selectedIds.remove(id)) {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedIds.isEmpty) {
      return;
    }
    _selectedIds.clear();
    notifyListeners();
  }

  // --- Expansion -----------------------------------------------------------

  void toggleExpanded(DateTime date) {
    if (!_expandedDates.remove(date)) {
      _expandedDates.add(date);
    }
    notifyListeners();
  }

  void expandAll() {
    _expandedDates
      ..clear()
      ..addAll(_sortedDates);
    notifyListeners();
  }

  void collapseAll() {
    _expandedDates.clear();
    notifyListeners();
  }

  // --- Mutations (persist, then reload) ------------------------------------

  /// Groups the currently selected records under a new meal. Returns the
  /// created meal, or null when nothing is selected.
  Future<Meal?> groupSelectedAsMeal(String title) async {
    final selected = _groupedCalories.values
        .expand((list) => list)
        .where((r) => r.id != null && _selectedIds.contains(r.id))
        .toList();
    if (selected.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final allEaten = selected.every((r) => r.isEaten());
    // Grouping is not asked for a day — the records already have their own. The
    // meal adopts theirs when they agree, and otherwise stays dayless; either
    // way the loop below leaves every member holding the meal's value, so the
    // group never spans two planned days.
    final firstDay = selected.first.plannedFor;
    final sharedDay =
        selected.every((r) => r.plannedFor == firstDay) ? firstDay : null;
    final meal = await _mealRepository.insert(Meal(
      id: null,
      profileId: selected.first.profileId,
      title: title,
      createdAt: now,
      plannedFor: sharedDay,
      // Grouping after the fact: the meal was eaten when its last record was.
      eatenAt: allEaten
          ? selected
              .map((r) => r.eatenAt!)
              .reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    ));

    for (final record in selected) {
      record.mealId = meal.id;
      record.plannedFor = sharedDay;
      record.updatedAt = now;
      await _recordRepository.update(record);
    }

    _selectedIds.clear();
    await load();
    return meal;
  }

  /// Plans a meal from scratch (title and day only); ingredients are added in
  /// cooking mode. Returns the created meal.
  Future<Meal> createNewMeal(String title, {DateTime? plannedFor}) async {
    final profile = await _profileResolver.resolve();
    final meal = await _mealRepository.insert(Meal(
      id: null,
      profileId: profile.id!,
      title: title,
      createdAt: DateTime.now(),
      plannedFor: plannedFor,
    ));
    await load();
    return meal;
  }

  /// "Cook it again": a new planned meal with planned copies of [source]'s
  /// records — same ingredients and last-used weights, under a name and day of
  /// their own. Returns the new meal.
  Future<Meal> duplicateMeal(
    Meal source,
    List<CalorieRecord> members, {
    String? title,
    DateTime? plannedFor,
  }) async {
    final now = DateTime.now();
    final meal = await _mealRepository.insert(Meal(
      id: null,
      profileId: source.profileId,
      title: title ?? source.title,
      createdAt: now,
      plannedFor: plannedFor,
      cookingMinutes: source.cookingMinutes,
    ));

    for (final record in members) {
      final copy = record.copyForPlanning(now, plannedFor: plannedFor);
      copy.mealId = meal.id;
      await _recordRepository.insert(copy);
    }

    await load();
    return meal;
  }

  Future<void> markMealEaten(Meal meal, List<CalorieRecord> members) async {
    final now = DateTime.now();
    meal.eatenAt = now;
    meal.updatedAt = now;
    await _mealRepository.update(meal);
    for (final record in members) {
      if (!record.isEaten()) {
        record.eatenAt = now;
        record.updatedAt = now;
        await _recordRepository.update(record);
      }
    }
    await load();
  }

  Future<void> ungroupMeal(Meal meal, List<CalorieRecord> members) async {
    final now = DateTime.now();
    for (final record in members) {
      record.mealId = null;
      record.updatedAt = now;
      await _recordRepository.update(record);
    }
    await _mealRepository.delete(meal);
    await load();
  }

  /// Deletes a meal together with every record in it. Records go first so a
  /// failure mid-way cannot leave them pointing at a meal that is gone.
  Future<void> deleteMeal(Meal meal, List<CalorieRecord> members) async {
    for (final record in members) {
      await _recordRepository.delete(record);
    }
    await _mealRepository.delete(meal);
    await load();
  }

  Future<void> removeFromMeal(CalorieRecord item) async {
    final mealId = item.mealId;
    item.mealId = null;
    item.updatedAt = DateTime.now();
    await _recordRepository.update(item);
    await _deleteMealIfEmptied(mealId, item);
    await load();
  }

  /// Moves [item] into an existing [target] meal. Returns the source meal when
  /// [item] was its last member — it is deleted, and the caller names it in the
  /// confirmation so the removal is not silent.
  Future<Meal?> moveToMeal(CalorieRecord item, Meal target) async {
    final targetId = target.id;
    final sourceMealId = item.mealId;
    if (targetId == null || targetId == sourceMealId) {
      return null;
    }
    item.mealId = targetId;
    // The record joins the target's day too, or it would sit under a different
    // day from the dish it now belongs to.
    item.plannedFor = target.plannedFor;
    item.updatedAt = DateTime.now();
    await _recordRepository.update(item);
    final emptied = await _deleteMealIfEmptied(sourceMealId, item);
    await load();
    return emptied;
  }

  /// Meals a record on [date] can join without its group splitting across two
  /// day cards: meals that already have a member that day, plus meals with no
  /// members at all (planned ahead, never filled). Same-day meals come first,
  /// newest first within each half. [excludeMealId] drops the record's own
  /// meal from the offer.
  List<Meal> mealCandidatesFor(DateTime date, {String? excludeMealId}) {
    final dateKey = DateTime(date.year, date.month, date.day);
    bool isOnDate(CalorieRecord record) {
      final createdAt = record.createdAt;
      return DateTime(createdAt.year, createdAt.month, createdAt.day) ==
          dateKey;
    }

    final sameDay = <Meal>[];
    final empty = <Meal>[];
    for (final meal in _mealsById.values) {
      if (meal.id == excludeMealId) {
        continue;
      }
      final members = _membersByMeal[meal.id!] ?? const <CalorieRecord>[];
      if (members.isEmpty) {
        empty.add(meal);
      } else if (members.any(isOnDate)) {
        sameDay.add(meal);
      }
    }

    int byNewest(Meal a, Meal b) => b.createdAt.compareTo(a.createdAt);
    sameDay.sort(byNewest);
    empty.sort(byNewest);
    return [...sameDay, ...empty];
  }

  /// Deletes the meal [item] just left when it was the last member, so an
  /// accidental leftover does not linger. A meal with a planned day survives
  /// being emptied: the day was chosen deliberately, it still renders on that
  /// day with no records, and losing a plan because its last ingredient moved
  /// elsewhere would be a silent deletion of something the user asked for.
  /// Returns the deleted meal, or null when nothing was deleted.
  Future<Meal?> _deleteMealIfEmptied(String? mealId, CalorieRecord item) async {
    final meal = mealId == null ? null : _mealsById[mealId];
    if (meal == null || meal.plannedFor != null) {
      return null;
    }
    // The members map predates the move, so exclude the moved record by id.
    final others = (_membersByMeal[mealId] ?? const <CalorieRecord>[])
        .where((r) => r.id != item.id);
    if (others.isNotEmpty) {
      return null;
    }
    await _mealRepository.delete(meal);
    return meal;
  }

  Future<void> setColorLabel(CalorieRecord item, ColorLabel? color) async {
    item.colorLabel = color;
    item.updatedAt = DateTime.now();
    await _recordRepository.update(item);
    await load();
  }

  /// Persists an already-edited meal (fields mutated by the caller), then pulls
  /// its members' planned day back in line with the meal's own. The day is
  /// denormalized onto each record so the day a record belongs to can be read
  /// from the record alone; the meal is the unit that owns it, so moving the
  /// meal moves every ingredient with it. Only records that actually differ are
  /// written, to keep a rename from bumping updatedAt on the whole dish.
  Future<void> saveMeal(Meal meal) async {
    await _mealRepository.update(meal);
    final now = DateTime.now();
    for (final record in _membersByMeal[meal.id] ?? const <CalorieRecord>[]) {
      if (record.plannedFor == meal.plannedFor) {
        continue;
      }
      record.plannedFor = meal.plannedFor;
      record.updatedAt = now;
      await _recordRepository.update(record);
    }
    await load();
  }
}
