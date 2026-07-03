import 'package:cat_calories/app/profile_resolver.dart';
import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/macro_chips.dart';
import 'package:cat_calories/features/calorie_tracking/ui/edit_calorie_item_screen.dart';
import 'package:cat_calories/features/calorie_tracking/ui/proportional_edit_bottom_sheet.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record_repository_interface.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/meal_repository_interface.dart';
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

  Future<void> _editWeight(CalorieRecord item) async {
    if (item.weightGrams == null || item.weightGrams! <= 0) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditCalorieItemScreen(item)),
      );
      _markChanged();
      await _load();
      return;
    }

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
      builder: (_) => _ProductPickerSheet(
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
        appBar: AppBar(
          title: Text(meal.title),
          elevation: 0,
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
                    onEdit: _editWeight,
                    onRemove: _removeIngredient,
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
                  const SizedBox(height: 32),
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
    final totalKcal = members.fold<double>(0, (sum, r) => sum + r.value);
    final totalWeight = members.fold<double>(
        0, (sum, r) => sum + (r.weightGrams ?? 0));
    double protein = 0, fat = 0, carbs = 0;
    bool hasMacros = false;
    final costs = <String, double>{};
    for (final r in members) {
      if (r.proteinGrams != null || r.fatGrams != null || r.carbGrams != null) {
        hasMacros = true;
        protein += r.proteinGrams ?? 0;
        fat += r.fatGrams ?? 0;
        carbs += r.carbGrams ?? 0;
      }
      if (r.costValue != null) {
        final currency = r.costCurrency ?? '?';
        costs[currency] = (costs[currency] ?? 0) + r.costValue!;
      }
    }

    final chips = <String>[
      '${totalKcal.toStringAsFixed(0)} kcal',
      if (totalWeight > 0) '${totalWeight.toStringAsFixed(0)}g',
      for (final entry in costs.entries)
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
          if (hasMacros) ...[
            const SizedBox(height: 10),
            MacroBadgesRow(protein: protein, fat: fat, carbs: carbs),
          ],
        ],
      ),
    );
  }
}

class _IngredientsCard extends StatelessWidget {
  final List<CalorieRecord> members;
  final void Function(CalorieRecord) onEdit;
  final void Function(CalorieRecord) onRemove;
  final VoidCallback onAdd;

  const _IngredientsCard({
    required this.members,
    required this.onEdit,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final item in members)
            _IngredientRow(
              item: item,
              onTap: () => onEdit(item),
              onRemove: () => onRemove(item),
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

class _IngredientRow extends StatelessWidget {
  final CalorieRecord item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _IngredientRow({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description ?? 'No description',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (item.weightGrams != null)
                        '${item.weightGrams!.toStringAsFixed(0)}g',
                      '${item.value.toStringAsFixed(0)} kcal',
                      if (item.costValue != null)
                        '${item.costValue!.toStringAsFixed(2)} ${item.costCurrency ?? ''}'
                            .trim(),
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.scale, size: 16, color: appColors.textDisabled),
            IconButton(
              icon: Icon(Icons.remove_circle_outline,
                  size: 20, color: DangerLiteColor),
              tooltip: 'Remove ingredient',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final ProductRepositoryInterface productsRepo;
  final Profile profile;

  const _ProductPickerSheet({
    required this.productsRepo,
    required this.profile,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  List<Product> _products = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String query) async {
    _query = query;
    final results = query.trim().isEmpty
        ? await widget.productsRepo.fetchRecentlyUsed(widget.profile, limit: 20)
        : await widget.productsRepo.search(widget.profile, query.trim());
    // Out-of-order responses: drop results for a stale query.
    if (mounted && query == _query) {
      setState(() => _products = results);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search products…',
                  ),
                  onChanged: _search,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final parts = <String>[
                      if (product.caloriesPer100g != null)
                        '${product.caloriesPer100g!.toStringAsFixed(0)} kcal/100g',
                      if (product.hasPrice)
                        '${product.pricePerPackage!.toStringAsFixed(2)} '
                            '${product.priceCurrency ?? ''} / '
                            '${product.packageWeightGrams!.toStringAsFixed(0)}g',
                    ];
                    return ListTile(
                      title: Text(product.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: parts.isEmpty
                          ? null
                          : Text(
                              parts.join(' · '),
                              style: TextStyle(
                                fontSize: 12,
                                color: appColors.textSecondary,
                              ),
                            ),
                      onTap: () => Navigator.of(context).pop(product),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
