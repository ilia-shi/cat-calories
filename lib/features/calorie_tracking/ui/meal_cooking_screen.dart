import 'package:cat_calories/app/profile_resolver.dart';
import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/app_floating_action_button.dart';
import 'package:cat_calories/common/widgets/app_top_bar.dart';
import 'package:cat_calories/common/widgets/calculator/calorie_calculator_sheet.dart';
import 'package:cat_calories/common/widgets/macro_chips.dart';
import 'package:cat_calories/features/calorie_tracking/ui/edit_calorie_item_screen.dart';
import 'package:cat_calories/features/calorie_tracking/ui/proportional_edit_bottom_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/calorie_record_row.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/item_options_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/product_picker_sheet.dart';
import 'package:cat_calories/features/calorie_tracking/ui/widgets/record_calculator_edit_sheet.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/color_label.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/cooked_meal_product.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_totals.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/products/domain/product_repository_interface.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cooking mode: adjust a meal's ingredients while actually cooking it —
/// inline weight edits (kcal/macros/cost recompute), add/remove ingredients,
/// one-tap "Eaten" when the meal hits the table.
class MealCookingScreen extends StatefulWidget {
  final Meal meal;

  const MealCookingScreen(this.meal, {super.key});

  @override
  State<MealCookingScreen> createState() => _MealCookingScreenState();
}

class _MealCookingScreenState extends State<MealCookingScreen> {
  final _recordsRepo = locator.get<CalorieRecordRepositoryInterface>();
  final _mealRepo = locator.get<MealRepositoryInterface>();
  final _productsRepo = locator.get<ProductRepositoryInterface>();

  Profile? _profile;
  List<CalorieRecord> _members = [];
  bool _isLoading = true;
  bool _changed = false;

  Meal get meal => widget.meal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileResolver().resolve();
    final all = await _recordsRepo.fetchAllByProfile(
      profile,
      orderBy: 'created_at ASC',
    );
    if (mounted) {
      setState(() {
        _profile = profile;
        _members = all.where((r) => r.mealId == meal.id).toList();
        _isLoading = false;
      });
    }
  }

  void _markChanged() {
    _changed = true;
  }

  /// The same per-record action sheet the history screen uses, so an
  /// ingredient offers every edit here that it does there. Moving to another
  /// meal is the exception: this screen is one meal's workbench.
  void _showItemOptions(CalorieRecord item) {
    ItemOptionsSheet.show(
      context,
      item: item,
      mealTitle: meal.title,
      canMoveToMeal: false,
      onMoveToMeal: () {},
      onAdjustWeight: () => _adjustWeight(item),
      onEditValues: () => _editIngredient(item),
      onEdit: () => _openFullEdit(item),
      onToggleEaten: () => _toggleEaten(item),
      onRemoveFromMeal: () => _removeFromMeal(item),
      onDelete: () => _removeIngredient(item),
      onColorLabelChanged: (color) => _setColorLabel(item, color),
    );
  }

  Future<void> _openFullEdit(CalorieRecord item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditCalorieItemScreen(item)),
    );
    _markChanged();
    await _load();
  }

  Future<void> _toggleEaten(CalorieRecord item) async {
    item.eatenAt = item.isEaten() ? null : DateTime.now();
    item.updatedAt = DateTime.now();
    await _recordsRepo.update(item);
    _markChanged();
    await _load();
  }

  /// Detaches the record from the dish without deleting it — the meal itself
  /// survives even when this empties it, since the user is standing on it.
  Future<void> _removeFromMeal(CalorieRecord item) async {
    item.mealId = null;
    item.updatedAt = DateTime.now();
    await _recordsRepo.update(item);
    _markChanged();
    await _load();
  }

  Future<void> _setColorLabel(CalorieRecord item, ColorLabel? color) async {
    item.colorLabel = color;
    item.updatedAt = DateTime.now();
    await _recordsRepo.update(item);
    _markChanged();
    await _load();
  }

  /// Full edit of an ingredient's numbers on the keypad — weight, calories and
  /// macros independently, unlike the proportional weight sheet.
  Future<void> _editIngredient(CalorieRecord item) async {
    await RecordCalculatorEditSheet.show(
      context,
      item: item,
      onSave: (result) async {
        item.value = result.calories;
        if (result.weightGrams != null) {
          item.weightGrams = result.weightGrams;
          item.proteinGrams = result.proteinGrams;
          item.fatGrams = result.fatGrams;
          item.carbGrams = result.carbGrams;
          await _recomputeCost(item);
        }
        item.updatedAt = DateTime.now();
        await _recordsRepo.update(item);
        _markChanged();
        await _load();
      },
    );
  }

  void _adjustWeight(CalorieRecord item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ProportionalEditBottomSheet(
        item: item,
        onSave: (result) async {
          Navigator.pop(sheetContext);
          item.weightGrams = result.weightGrams;
          item.value = result.calories;
          item.proteinGrams = result.proteinGrams;
          item.fatGrams = result.fatGrams;
          item.carbGrams = result.carbGrams;
          await _recomputeCost(item);
          item.updatedAt = DateTime.now();
          await _recordsRepo.update(item);
          _markChanged();
          await _load();
        },
      ),
    );
  }

  /// Master plan edit/recompute story: weight change re-derives the cost
  /// snapshot from the product's current price unless the user set the cost
  /// by hand.
  Future<void> _recomputeCost(CalorieRecord item) async {
    if (item.costIsManual || item.productId == null) {
      return;
    }
    final product = await _productsRepo.find(item.productId!);
    if (product == null || !product.hasPrice) {
      return;
    }
    item.costValue = product.calculateCost(item.weightGrams ?? 0);
    item.costCurrency = product.priceCurrency;
  }

  Future<void> _removeIngredient(CalorieRecord item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove ingredient'),
        content: Text(
            'Delete "${item.description ?? 'this entry'}" from the meal and the log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DangerColor),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await _recordsRepo.delete(item);
    _markChanged();
    await _load();
  }

  Future<void> _addIngredient() async {
    if (_profile == null) {
      return;
    }
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      shape: AppCard.squircleBorder(radius: 20, bottom: false),
      builder: (_) => ProductPickerSheet(
        productsRepo: _productsRepo,
        profile: _profile!,
      ),
    );
    if (product == null || !mounted) {
      return;
    }

    final weight = await _promptWeight(product);
    if (weight == null || weight <= 0) {
      return;
    }

    final now = DateTime.now();
    final record = CalorieRecord(
      id: null,
      value: product.calculateCalories(weight) ?? 0,
      description: product.title,
      sortOrder: 0,
      // New ingredients follow the meal's state: still planned, or already
      // part of an eaten meal.
      eatenAt: meal.isEaten() ? now : null,
      createdAt: now,
      profileId: _profile!.id!,
      wakingPeriodId: null,
      weightGrams: weight,
      proteinGrams: product.calculateProtein(weight),
      fatGrams: product.calculateFat(weight),
      carbGrams: product.calculateCarbs(weight),
      productId: product.id,
      mealId: meal.id,
      costValue: product.calculateCost(weight),
      costCurrency:
          product.calculateCost(weight) == null ? null : product.priceCurrency,
    );
    await _recordsRepo.insert(record);
    _markChanged();
    await _load();
  }

  /// Adds an ingredient the product catalogue doesn't cover — a pinch of oil,
  /// a guessed portion — straight from the calculator keypad.
  Future<void> _addFromCalculator() async {
    if (_profile == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (sheetContext) => CalorieCalculatorSheet(
        submitLabel: 'Add',
        onSubmit: (result) async {
          Navigator.pop(sheetContext);
          await _insertCalculated(result);
        },
      ),
    );
  }

  Future<void> _insertCalculated(CalorieCalculatorResult result) async {
    final now = DateTime.now();
    final record = CalorieRecord(
      id: null,
      value: result.calories,
      description: null,
      sortOrder: 0,
      // New ingredients follow the meal's state: still planned, or already
      // part of an eaten meal.
      eatenAt: meal.isEaten() ? now : null,
      createdAt: now,
      profileId: _profile!.id!,
      wakingPeriodId: null,
      weightGrams: result.weightGrams,
      proteinGrams: result.proteinGrams,
      fatGrams: result.fatGrams,
      carbGrams: result.carbGrams,
      mealId: meal.id,
    );
    await _recordsRepo.insert(record);
    _markChanged();
    await _load();
  }

  Future<double?> _promptWeight(Product product) {
    final controller = TextEditingController(
      text: product.packageWeightGrams?.toStringAsFixed(0) ?? '',
    );
    return showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(product.title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight',
            suffixText: 'g',
          ),
          onSubmitted: (value) =>
              Navigator.of(dialogContext).pop(double.tryParse(value)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(double.tryParse(controller.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _markMealEaten() async {
    final now = DateTime.now();
    meal.eatenAt = now;
    meal.updatedAt = now;
    await _mealRepo.update(meal);
    for (final record in _members) {
      if (!record.isEaten()) {
        record.eatenAt = now;
        record.updatedAt = now;
        await _recordsRepo.update(record);
      }
    }
    _markChanged();
    if (mounted) {
      setState(() {});
      await _load();
    }
  }

  /// Leftovers flow: with the total cooked weight known, the dish becomes an
  /// ordinary per-100g product — tomorrow's portion is one record by weight.
  Future<void> _saveAsProduct() async {
    if (_members.isEmpty) {
      return;
    }
    final ingredientWeight = _members.fold<double>(
        0, (sum, r) => sum + (r.weightGrams ?? 0));
    final prefill = meal.totalCookedWeightGrams ??
        (ingredientWeight > 0 ? ingredientWeight : null);
    final controller = TextEditingController(
      text: prefill?.toStringAsFixed(0) ?? '',
    );

    final weight = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save as product'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Total cooked weight',
            suffixText: 'g',
            helperText: 'Weigh the finished dish — water loss makes it '
                'lighter than the raw ingredients',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (weight == null || weight <= 0) {
      return;
    }

    final now = DateTime.now();
    meal.totalCookedWeightGrams = weight;
    meal.updatedAt = now;
    await _mealRepo.update(meal);

    final product = CookedMealProduct.build(
      meal: meal,
      records: _members,
      cookedWeightGrams: weight,
      now: now,
    );
    if (product == null) {
      return;
    }
    await _productsRepo.insert(product);
    _markChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Product "${product.title}" created — log leftovers by weight'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _notifyAndPop() {
    if (_changed) {
      BlocProvider.of<HomeBloc>(context)
          .add(CalorieItemListFetchingInProgressEvent());
    }
    Navigator.of(context).pop(_changed);
  }

  @override
  Widget build(BuildContext context) {
    final hasUneaten = !meal.isEaten() || _members.any((r) => !r.isEaten());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _notifyAndPop();
        }
      },
      child: Scaffold(
        appBar: AppTopBar(title: meal.title),
        floatingActionButton: AppFloatingActionButton(
          // Its own tag: without one it would fly out of the home screen's FAB
          // on push, dragging a blurred circle across the transition.
          heroTag: 'meal-cooking-fab',
          onPressed: _isLoading ? null : _addFromCalculator,
          tooltip: 'Add calories',
          child: const Icon(Icons.add),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _TotalsCard(meal: meal, members: _members),
                  const SizedBox(height: 16),
                  _IngredientsCard(
                    members: _members,
                    onOptions: _showItemOptions,
                    onAdd: _addIngredient,
                  ),
                  const SizedBox(height: 24),
                  if (hasUneaten)
                    ElevatedButton.icon(
                      onPressed: _markMealEaten,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SuccessColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: AppCard.squircleBorder(radius: 14),
                      ),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark Meal as Eaten'),
                    ),
                  if (_members.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _saveAsProduct,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: AppCard.squircleBorder(radius: 14),
                      ),
                      icon: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: const Text('Save as Product (leftovers)'),
                    ),
                  ],
                  // Clears the FAB so it never sits on the last button.
                  const SizedBox(height: 88),
                ],
              ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final Meal meal;
  final List<CalorieRecord> members;

  const _TotalsCard({required this.meal, required this.members});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final totals = MealTotals.of(members);

    final chips = <String>[
      '${totals.kcal.toStringAsFixed(0)} kcal',
      if (totals.hasWeight) '${totals.weightGrams.toStringAsFixed(0)}g',
      for (final entry in totals.costs.entries)
        '${entry.value.toStringAsFixed(2)} ${entry.key}',
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                meal.isEaten() ? Icons.check_circle : Icons.schedule,
                size: 18,
                color: meal.isEaten() ? SuccessColor : appColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                meal.isEaten() ? 'Eaten' : 'Planned',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: appColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                chips.join(' · '),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: appColors.textPrimary,
                ),
              ),
            ],
          ),
          if (totals.hasMacros) ...[
            const SizedBox(height: 10),
            MacroBadgesRow(
              protein: totals.protein,
              fat: totals.fat,
              carbs: totals.carbs,
            ),
          ],
        ],
      ),
    );
  }
}

class _IngredientsCard extends StatelessWidget {
  final List<CalorieRecord> members;
  final void Function(CalorieRecord) onOptions;
  final VoidCallback onAdd;

  const _IngredientsCard({
    required this.members,
    required this.onOptions,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < members.length; i++)
            CalorieRecordRow(
              item: members[i],
              isSelected: false,
              // The card's own divider closes the list under the last row.
              isLast: i == members.length - 1,
              showDetails: true,
              onTap: () => onOptions(members[i]),
            ),
          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No ingredients yet — add the first one below',
                style: TextStyle(fontSize: 13, color: appColors.textTertiary),
              ),
            ),
          Container(height: 1, color: appColors.borderSubtle),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add ingredient'),
          ),
        ],
      ),
    );
  }
}
