import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/calculator/calorie_calculator_sheet.dart';
import 'package:cat_calories/common/widgets/floating_toolbar.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories/features/calorie_tracking/ui/edit_calorie_item_screen.dart';
import 'package:cat_calories/features/calorie_tracking/ui/meal_cooking_screen.dart';
import 'package:cat_calories/features/calorie_tracking/ui/meal_edit_screen.dart';
import 'package:cat_calories/features/calorie_tracking/ui/state/calories_history_controller.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/calorie_record_row.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/date_group_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/delete_entry_dialog.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/delete_meal_dialog.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/history_empty_state.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/history_summary_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/meal_group_block.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/meal_options_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/meal_picker_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/meal_title_dialog.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/item_options_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/record_calculator_edit_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/proportional_edit_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AllCaloriesHistoryScreen extends StatefulWidget {
  const AllCaloriesHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AllCaloriesHistoryScreen> createState() =>
      _AllCaloriesHistoryScreenState();
}

class _AllCaloriesHistoryScreenState extends State<AllCaloriesHistoryScreen>
    with AutomaticKeepAliveClientMixin {
  final CaloriesHistoryController _controller = CaloriesHistoryController();
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.load(showLoading: true);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    final error = _controller.takeError();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<HomeBloc, AbstractHomeState>(
      listener: (context, state) {
        if (state is HomeFetched) {
          _controller.load();
        }
      },
      child: Scaffold(
        body: FloatingToolbarHost(
          toolbars: (context, collapseProgress) => FloatingToolbar(
            collapseProgress: collapseProgress,
            children: _controller.hasSelection
                ? _selectionToolbar(context)
                : _mainToolbar(context),
          ),
          builder: (context, topInset) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_controller.sortedDates.isEmpty) {
              return Padding(
                padding: EdgeInsets.only(top: topInset),
                child: const HistoryEmptyState(),
              );
            }
            return _buildContent(topInset);
          },
        ),
      ),
    );
  }

  List<Widget> _selectionToolbar(BuildContext context) {
    return [
      ToolbarActionButton(
        icon: Icons.close,
        tooltip: 'Cancel selection',
        onPressed: _controller.clearSelection,
      ),
      const SizedBox(width: 4),
      Text(
        '${_controller.selectionCount} selected',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.of(context).textPrimary,
        ),
      ),
      const Spacer(),
      TextButton.icon(
        onPressed: _groupSelectedAsMeal,
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.restaurant, size: 18),
        label: const Text('Group as meal'),
      ),
    ];
  }

  List<Widget> _mainToolbar(BuildContext context) {
    return [
      Text(
        'Calorie History',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.of(context).textPrimary,
        ),
      ),
      const Spacer(),
      PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 22,
        onSelected: (value) {
          if (value == 'new_meal') {
            _createNewMeal();
          } else if (value == 'expand_all') {
            _controller.expandAll();
          } else if (value == 'collapse_all') {
            _controller.collapseAll();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'new_meal',
            child: Row(
              children: [
                Icon(Icons.restaurant, size: 20),
                SizedBox(width: 12),
                Text('New Meal (plan ahead)'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'expand_all',
            child: Row(
              children: [
                Icon(Icons.unfold_more, size: 20),
                SizedBox(width: 12),
                Text('Expand All'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'collapse_all',
            child: Row(
              children: [
                Icon(Icons.unfold_less, size: 20),
                SizedBox(width: 12),
                Text('Collapse All'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildContent(double topInset) {
    final sortedDates = _controller.sortedDates;
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView.builder(
        controller: _scrollController,
        primary: false,
        padding: EdgeInsets.only(top: topInset, bottom: 24),
        itemCount: sortedDates.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return HistorySummaryCard(
              totalDays: sortedDates.length,
              totalItems: _controller.totalItems,
              totalCalories: _controller.totalAllTime,
              totalProtein: _controller.totalProtein,
              totalFat: _controller.totalFat,
              totalCarbs: _controller.totalCarbs,
            );
          }
          return _buildDateGroup(sortedDates[index - 1]);
        },
      ),
    );
  }

  Widget _buildDateGroup(DateTime date) {
    final isExpanded = _controller.isExpanded(date);
    final items = _controller.groupedCalories[date] ?? [];
    return DateGroupCard(
      date: date,
      summary: _controller.daySummaries[date]!,
      isExpanded: isExpanded,
      onToggle: () => _controller.toggleExpanded(date),
      // Collapsed days build none of their rows.
      dayItems: isExpanded ? _buildDayItems(items) : const [],
    );
  }

  /// A day's rows with meal groups inline: each meal becomes one enclosed
  /// block, ungrouped records stay plain rows. Order follows first appearance
  /// in [items], so days without meals render exactly as before.
  List<Widget> _buildDayItems(List<CalorieRecord> items) {
    // Group members by meal in a single pass, instead of an O(n) `.where` scan
    // per meal (which made the whole day O(n²) on every rebuild).
    final membersByMeal = <String, List<CalorieRecord>>{};
    for (final item in items) {
      final mealId = item.mealId;
      if (mealId != null) {
        (membersByMeal[mealId] ??= <CalorieRecord>[]).add(item);
      }
    }

    final entries = <_DayEntry>[];
    final emittedMealIds = <String>{};
    for (final item in items) {
      final meal =
          item.mealId == null ? null : _controller.mealsById[item.mealId];
      if (meal == null) {
        entries.add(_DayEntry.record(item));
        continue;
      }
      if (!emittedMealIds.add(meal.id!)) {
        continue;
      }
      entries.add(_DayEntry.meal(
        meal,
        membersByMeal[meal.id!] ?? const <CalorieRecord>[],
      ));
    }

    return [
      for (int i = 0; i < entries.length; i++)
        _buildDayEntry(entries[i], isLast: i == entries.length - 1),
    ];
  }

  Widget _buildDayEntry(_DayEntry entry, {required bool isLast}) {
    final meal = entry.meal;
    final records = entry.records;
    if (meal == null) {
      return _buildCalorieRow(records.first, isLast);
    }
    return MealGroupBlock(
      meal: meal,
      records: records,
      onHeaderTap: () => _showMealOptions(meal, records),
      // Rows carry no divider of their own: the block draws the separators
      // between members and its outline closes the group at the bottom.
      rows: [
        for (final member in records) _buildCalorieRow(member, true),
      ],
    );
  }

  Widget _buildCalorieRow(CalorieRecord item, bool isLast) {
    return CalorieRecordRow(
      item: item,
      isLast: isLast,
      isSelected: _controller.isSelected(item.id),
      onTap: () {
        if (_controller.hasSelection) {
          _controller.toggleSelection(item);
        } else {
          _showItemOptions(item);
        }
      },
      onLongPress: () => _controller.toggleSelection(item),
    );
  }

  void _showItemOptions(CalorieRecord item) {
    ItemOptionsSheet.show(
      context,
      item: item,
      mealTitle: item.mealId == null
          ? null
          : _controller.mealsById[item.mealId]?.title,
      canMoveToMeal: _moveTargetsFor(item).isNotEmpty,
      onMoveToMeal: () => _moveToMeal(item),
      onAdjustWeight: () => _showProportionalEdit(item),
      onEditValues: () => _showCalculatorEdit(item),
      onEdit: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditCalorieItemScreen(item),
          ),
        ).then((_) => _controller.load());
      },
      onToggleEaten: () {
        BlocProvider.of<HomeBloc>(context).add(
          CalorieItemEatingEvent(item),
        );
        Future.delayed(const Duration(milliseconds: 300), () {
          _controller.load();
        });
      },
      onRemoveFromMeal: () => _removeFromMeal(item),
      onDelete: () => _confirmDelete(item),
      onColorLabelChanged: (color) => _controller.setColorLabel(item, color),
    );
  }

  List<Meal> _moveTargetsFor(CalorieRecord item) {
    return _controller.mealCandidatesFor(
      item.createdAt,
      excludeMealId: item.mealId,
    );
  }

  Future<void> _moveToMeal(CalorieRecord item) async {
    final target = await MealPickerSheet.show(
      context,
      item: item,
      meals: _moveTargetsFor(item),
      membersByMeal: _controller.membersByMeal,
    );
    if (target == null) {
      return;
    }
    final emptied = await _controller.moveToMeal(item, target);
    _afterMealMutation(
      emptied == null
          ? 'Moved to "${target.title}"'
          : 'Moved to "${target.title}" — empty meal "${emptied.title}" removed',
    );
  }

  Future<void> _groupSelectedAsMeal() async {
    final title = await promptMealTitle(context);
    if (title == null || title.trim().isEmpty) {
      return;
    }
    final meal = await _controller.groupSelectedAsMeal(title.trim());
    if (meal == null) {
      return;
    }
    _afterMealMutation('Meal "${meal.title}" created');
  }

  Future<void> _openCookingScreen(Meal meal) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MealCookingScreen(meal)),
    );
    _controller.load();
  }

  Future<void> _duplicateMeal(Meal source, List<CalorieRecord> members) async {
    final meal = await _controller.duplicateMeal(source, members);
    _afterMealMutation('Planned "${meal.title}" — adjust it while cooking');
    await _openCookingScreen(meal);
  }

  Future<void> _createNewMeal() async {
    final title = await promptMealTitle(
      context,
      dialogTitle: 'New planned meal',
      confirmLabel: 'Plan',
    );
    if (title == null || title.trim().isEmpty) {
      return;
    }
    final meal = await _controller.createNewMeal(title.trim());
    _afterMealMutation('Meal "${meal.title}" planned');
    await _openCookingScreen(meal);
  }

  void _showMealOptions(Meal meal, List<CalorieRecord> members) {
    MealOptionsSheet.show(
      context,
      meal: meal,
      members: members,
      onCookingMode: () => _openCookingScreen(meal),
      onDuplicate: () => _duplicateMeal(meal, members),
      onEdit: () => _openMealEditScreen(meal),
      onMarkEaten: () => _markMealEaten(meal, members),
      onUngroup: () => _ungroupMeal(meal, members),
      onDelete: () => _confirmDeleteMeal(meal, members),
    );
  }

  Future<void> _openMealEditScreen(Meal meal) async {
    final result = await MealEditScreen.push(context, meal);
    if (result == null) {
      return;
    }
    if (result.title != null) {
      meal.title = result.title!;
    }
    meal.notes = result.notes;
    meal.cookingMinutes = result.cookingMinutes;
    meal.tasteRating = result.tasteRating;
    meal.satietyRating = result.satietyRating;
    meal.updatedAt = DateTime.now();
    await _controller.saveMeal(meal);
    _afterMealMutation('Meal updated');
  }

  Future<void> _markMealEaten(Meal meal, List<CalorieRecord> members) async {
    await _controller.markMealEaten(meal, members);
    _afterMealMutation('Meal marked as eaten');
  }

  Future<void> _ungroupMeal(Meal meal, List<CalorieRecord> members) async {
    await _controller.ungroupMeal(meal, members);
    _afterMealMutation('Meal ungrouped');
  }

  void _confirmDeleteMeal(Meal meal, List<CalorieRecord> members) {
    DeleteMealDialog.show(
      context,
      meal: meal,
      recordCount: members.length,
      totalCalories: members.fold<double>(0, (sum, r) => sum + r.value),
      onConfirm: () => _deleteMeal(meal, members),
    );
  }

  Future<void> _deleteMeal(Meal meal, List<CalorieRecord> members) async {
    await _controller.deleteMeal(meal, members);
    _afterMealMutation('Meal "${meal.title}" deleted');
  }

  Future<void> _removeFromMeal(CalorieRecord item) async {
    await _controller.removeFromMeal(item);
    _afterMealMutation('Removed from meal');
  }

  /// Shared post-mutation UI: toast the outcome and nudge the rest of the app
  /// to refresh. The controller has already reloaded its own state.
  void _afterMealMutation(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    BlocProvider.of<HomeBloc>(context)
        .add(CalorieItemListFetchingInProgressEvent());
  }

  void _showCalculatorEdit(CalorieRecord item) {
    RecordCalculatorEditSheet.show(
      context,
      item: item,
      onSave: (result) => _applyCalculatorEdit(item, result),
    );
  }

  void _applyCalculatorEdit(CalorieRecord item, CalorieCalculatorResult result) {
    item.value = result.calories;
    // Quick Add yields a bare calorie amount: leave the record's weight and
    // macros as they were rather than wiping them.
    if (result.weightGrams != null) {
      item.weightGrams = result.weightGrams;
      item.proteinGrams = result.proteinGrams;
      item.fatGrams = result.fatGrams;
      item.carbGrams = result.carbGrams;
    }

    BlocProvider.of<HomeBloc>(context).add(
      CalorieItemListUpdatingEvent(item, [], () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated to ${item.value.toStringAsFixed(0)} kcal'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        _controller.load();
      }),
    );
  }

  void _showProportionalEdit(CalorieRecord item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ProportionalEditBottomSheet(
          item: item,
          onSave: (result) {
            Navigator.pop(sheetContext);
            _applyProportionalEdit(item, result);
          },
        );
      },
    );
  }

  void _applyProportionalEdit(
      CalorieRecord item, ProportionalEditResult result) {
    item.weightGrams = result.weightGrams;
    item.value = result.calories;
    item.proteinGrams = result.proteinGrams;
    item.fatGrams = result.fatGrams;
    item.carbGrams = result.carbGrams;

    BlocProvider.of<HomeBloc>(context).add(
      CalorieItemListUpdatingEvent(item, [], () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Updated to ${result.weightGrams.toStringAsFixed(0)}g • ${result.calories.toStringAsFixed(0)} kcal'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        _controller.load();
      }),
    );
  }

  void _confirmDelete(CalorieRecord item) {
    DeleteEntryDialog.show(
      context,
      item: item,
      onConfirm: () {
        BlocProvider.of<HomeBloc>(context).add(
          RemovingCalorieItemEvent(item, [], () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Entry deleted successfully'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
            _controller.load();
          }),
        );
      },
    );
  }
}

/// One top-level entry in a day's list: either a meal (rendered as a group
/// block over its [records]) or a single ungrouped record.
class _DayEntry {
  final Meal? meal;
  final List<CalorieRecord> records;

  _DayEntry.meal(Meal this.meal, this.records);

  _DayEntry.record(CalorieRecord record)
      : meal = null,
        records = [record];
}
