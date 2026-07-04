import 'package:cat_calories/app/profile_resolver.dart';
import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/day_summary.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_repository_interface.dart';
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
    double total = 0;
    int itemCount = 0;
    double totalProtein = 0;
    double totalFat = 0;
    double totalCarbs = 0;

    for (final calorie in records) {
      final dateKey = DateTime(
        calorie.createdAt.year,
        calorie.createdAt.month,
        calorie.createdAt.day,
      );

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
        summaries[dateKey] = DaySummary();
      }
      final summary = summaries[dateKey]!;
      grouped[dateKey]!.add(calorie);
      summary.itemCount++;
      itemCount++;

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

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    _mealsById = {
      for (final meal in meals)
        if (meal.id != null) meal.id!: meal,
    };
    _groupedCalories = grouped;
    _daySummaries = summaries;
    _sortedDates = sortedDates;
    _totalAllTime = total;
    _totalItems = itemCount;
    _totalProtein = totalProtein;
    _totalFat = totalFat;
    _totalCarbs = totalCarbs;

    // Expand the first date by default only on the very first load.
    if (_isInitialLoad && sortedDates.isNotEmpty) {
      _expandedDates.add(sortedDates.first);
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
    final meal = await _mealRepository.insert(Meal(
      id: null,
      profileId: selected.first.profileId,
      title: title,
      createdAt: now,
      // Grouping after the fact: the meal was eaten when its last record was.
      eatenAt: allEaten
          ? selected
              .map((r) => r.eatenAt!)
              .reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    ));

    for (final record in selected) {
      record.mealId = meal.id;
      record.updatedAt = now;
      await _recordRepository.update(record);
    }

    _selectedIds.clear();
    await load();
    return meal;
  }

  /// Plans a meal from scratch (title only); ingredients are added in cooking
  /// mode. Returns the created meal.
  Future<Meal> createNewMeal(String title) async {
    final profile = await _profileResolver.resolve();
    final meal = await _mealRepository.insert(Meal(
      id: null,
      profileId: profile.id!,
      title: title,
      createdAt: DateTime.now(),
    ));
    await load();
    return meal;
  }

  /// "Cook it again": a new planned meal with planned copies of [source]'s
  /// records — same ingredients and last-used weights. Returns the new meal.
  Future<Meal> duplicateMeal(Meal source, List<CalorieRecord> members) async {
    final now = DateTime.now();
    final meal = await _mealRepository.insert(Meal(
      id: null,
      profileId: source.profileId,
      title: source.title,
      createdAt: now,
      cookingMinutes: source.cookingMinutes,
    ));

    for (final record in members) {
      final copy = record.copyForPlanning(now);
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

  Future<void> removeFromMeal(CalorieRecord item) async {
    final mealId = item.mealId;
    item.mealId = null;
    item.updatedAt = DateTime.now();
    await _recordRepository.update(item);

    // Removing the last member leaves an empty group — delete it too.
    final remaining = _groupedCalories.values
        .expand((list) => list)
        .where((r) => r.mealId == mealId && r.id != item.id);
    final meal = mealId == null ? null : _mealsById[mealId];
    if (remaining.isEmpty && meal != null) {
      await _mealRepository.delete(meal);
    }
    await load();
  }

  /// Persists an already-edited meal (fields mutated by the caller).
  Future<void> saveMeal(Meal meal) async {
    await _mealRepository.update(meal);
    await load();
  }
}
