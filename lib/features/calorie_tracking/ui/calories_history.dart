import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories/features/calorie_tracking/ui/edit_calorie_item_screen.dart';
import 'package:cat_calories/features/calorie_tracking/ui/meal_cooking_screen.dart';
import 'package:cat_calories/features/calorie_tracking/ui/state/calories_history_controller.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/calorie_record_row.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/date_group_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/delete_entry_dialog.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/history_empty_state.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/history_summary_card.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/item_options_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/meal_edit_dialog.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/meal_header_row.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/meal_options_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/history/meal_title_dialog.dart';
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
        appBar:
            _controller.hasSelection ? _buildSelectionAppBar() : _buildAppBar(),
        body: _controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _controller.sortedDates.isEmpty
                ? const HistoryEmptyState()
                : _buildContent(),
      ),
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      title: Text('${_controller.selectionCount} selected'),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Cancel selection',
        onPressed: _controller.clearSelection,
      ),
      actions: [
        TextButton.icon(
          onPressed: _groupSelectedAsMeal,
          icon: const Icon(Icons.restaurant, size: 18),
          label: const Text('Group as meal'),
        ),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Calorie History'),
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
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
      ],
    );
  }

  Widget _buildContent() {
    final sortedDates = _controller.sortedDates;
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView.builder(
        controller: _scrollController,
        primary: false,
        padding: const EdgeInsets.only(bottom: 24),
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
    final items = _controller.groupedCalories[date] ?? [];
    return DateGroupCard(
      date: date,
      summary: _controller.daySummaries[date]!,
      isExpanded: _controller.isExpanded(date),
      onToggle: () => _controller.toggleExpanded(date),
      dayItems: _buildDayItems(items),
    );
  }

  /// A day's rows with meal groups inline: a meal header followed by its
  /// member records, ungrouped records as plain rows. Order follows first
  /// appearance in [items], so days without meals render exactly as before.
  List<Widget> _buildDayItems(List<CalorieRecord> items) {
    final widgets = <Widget>[];
    final emittedMealIds = <String>{};

    for (final item in items) {
      final meal =
          item.mealId == null ? null : _controller.mealsById[item.mealId];
      if (meal == null) {
        widgets.add(_buildCalorieRow(item, item == items.last));
        continue;
      }
      if (emittedMealIds.contains(meal.id)) {
        continue;
      }
      emittedMealIds.add(meal.id!);

      final members = items.where((r) => r.mealId == meal.id).toList();
      widgets.add(MealHeaderRow(
        meal: meal,
        records: members,
        onTap: () => _showMealOptions(meal, members),
      ));
      for (final member in members) {
        widgets.add(_buildCalorieRow(member, member == items.last));
      }
    }

    return widgets;
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
      onAdjustWeight: () => _showProportionalEdit(item),
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
      onEdit: () => _showMealEditDialog(meal),
      onMarkEaten: () => _markMealEaten(meal, members),
      onUngroup: () => _ungroupMeal(meal, members),
    );
  }

  void _showMealEditDialog(Meal meal) {
    MealEditDialog.show(
      context,
      meal: meal,
      onSave: (result) async {
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
      },
    );
  }

  Future<void> _markMealEaten(Meal meal, List<CalorieRecord> members) async {
    await _controller.markMealEaten(meal, members);
    _afterMealMutation('Meal marked as eaten');
  }

  Future<void> _ungroupMeal(Meal meal, List<CalorieRecord> members) async {
    await _controller.ungroupMeal(meal, members);
    _afterMealMutation('Meal ungrouped');
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
