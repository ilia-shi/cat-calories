import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/theme/theme.dart';
import 'package:cat_calories/common/utils/expression_executor.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_keypad.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_sheet.dart';
import 'package:cat_calories/common/widgets/mode_button.dart';
import 'package:cat_calories/common/widgets/nutrition_calculator_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Input mode of the [CalorieCalculatorSheet].
enum CalorieInputMode {
  /// Simple mode - just enter calories quickly
  quickAdd,

  /// Nutrition calculator, entering calories per 100g directly
  enterCalories,

  /// Nutrition calculator, calories computed from macros
  fromMacros,
}

/// The last input mode the user picked, remembered across sheets so adding
/// calories reopens where they left off.
class _InputModeStore {
  static const String _inputModeKey = 'calorie_input_mode';
  static const String _nutritionCalcModeKey = 'nutrition_calc_mode';

  Future<CalorieInputMode?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString(_inputModeKey)) {
        case 'simple':
          return CalorieInputMode.quickAdd;
        case 'enterCalories':
          return CalorieInputMode.enterCalories;
        case 'fromMacros':
          return CalorieInputMode.fromMacros;
        case 'detailed':
          // Legacy value: resolve the nutrition sub-mode from its own pref.
          return prefs.getString(_nutritionCalcModeKey) == 'fromMacros'
              ? CalorieInputMode.fromMacros
              : CalorieInputMode.enterCalories;
      }
    } catch (e) {
      debugPrint('Failed to load input mode preference: $e');
    }
    return null;
  }

  Future<void> save(CalorieInputMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_inputModeKey, _toPref(mode));
      // Keep the nutrition sub-mode pref in sync for the calculator default.
      if (mode != CalorieInputMode.quickAdd) {
        await prefs.setString(
          _nutritionCalcModeKey,
          mode == CalorieInputMode.fromMacros ? 'fromMacros' : 'enterCalories',
        );
      }
    } catch (e) {
      // Silently fail - saving preference is not critical
      debugPrint('Failed to save input mode preference: $e');
    }
  }

  String _toPref(CalorieInputMode mode) {
    switch (mode) {
      case CalorieInputMode.quickAdd:
        return 'simple';
      case CalorieInputMode.enterCalories:
        return 'enterCalories';
      case CalorieInputMode.fromMacros:
        return 'fromMacros';
    }
  }
}

/// The numbers the user entered in a [CalorieCalculatorSheet].
class CalorieCalculatorResult {
  final double calories;

  /// Null in [CalorieInputMode.quickAdd] — a bare calorie amount carries no
  /// weight or macros.
  final double? weightGrams;
  final double? proteinGrams;
  final double? fatGrams;
  final double? carbGrams;

  /// The raw quick-add expression ('120+80'), null in the nutrition modes.
  /// Only for callers that hand the expression itself to a bloc; everyone else
  /// reads the already-evaluated [calories].
  final String? expression;

  const CalorieCalculatorResult({
    required this.calories,
    this.weightGrams,
    this.proteinGrams,
    this.fatGrams,
    this.carbGrams,
    this.expression,
  });
}

/// Keypad-driven calorie entry as a bottom sheet, shared by every screen that
/// logs or edits calories: quick add (an arithmetic expression), or the
/// nutrition calculator with calories entered directly or derived from macros.
///
/// It owns no persistence — the caller receives a [CalorieCalculatorResult]
/// and decides what to do with it. Passing the `initial*` values (actual
/// values of an existing record, not per 100g) turns it into an edit sheet.
class CalorieCalculatorSheet extends StatefulWidget {
  final void Function(CalorieCalculatorResult result) onSubmit;

  /// Called on every quick-add keystroke with the raw expression, for callers
  /// that preview the pending value elsewhere in the UI.
  final ValueChanged<String>? onQuickAddChanged;

  /// Blocks further submissions while the caller persists the last one.
  final bool isSubmitting;

  final Widget? header;
  final String submitLabel;

  final double? initialCalories;
  final double? initialWeightGrams;
  final double? initialProteinGrams;
  final double? initialFatGrams;
  final double? initialCarbGrams;

  const CalorieCalculatorSheet({
    Key? key,
    required this.onSubmit,
    this.onQuickAddChanged,
    this.isSubmitting = false,
    this.header,
    this.submitLabel = 'OK',
    this.initialCalories,
    this.initialWeightGrams,
    this.initialProteinGrams,
    this.initialFatGrams,
    this.initialCarbGrams,
  }) : super(key: key);

  @override
  State<CalorieCalculatorSheet> createState() => _CalorieCalculatorSheetState();
}

class _CalorieCalculatorSheetState extends State<CalorieCalculatorSheet> {
  final _modeStore = _InputModeStore();
  late final TextEditingController _quickAddController;
  CalorieInputMode _inputMode = CalorieInputMode.quickAdd;
  bool _isLoading = true;

  bool get _isEditing => widget.initialCalories != null;

  @override
  void initState() {
    super.initState();
    _quickAddController = TextEditingController(
      text: _isEditing ? _formatNumber(widget.initialCalories!) : '',
    );
    _quickAddController.addListener(_onQuickAddChanged);

    if (_isEditing) {
      // An edited record dictates the mode: weighed records open on the
      // nutrition calculator, everything else on the plain calorie field.
      _inputMode = (widget.initialWeightGrams ?? 0) > 0
          ? CalorieInputMode.enterCalories
          : CalorieInputMode.quickAdd;
      _isLoading = false;
      return;
    }
    _loadSavedMode();
  }

  @override
  void dispose() {
    _quickAddController.removeListener(_onQuickAddChanged);
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedMode() async {
    final mode = await _modeStore.load();
    if (mounted) {
      setState(() {
        if (mode != null) {
          _inputMode = mode;
        }
        _isLoading = false;
      });
    }
  }

  /// The nutrition calculator mode corresponding to the current input mode.
  NutritionInputMode get _nutritionMode =>
      _inputMode == CalorieInputMode.fromMacros
          ? NutritionInputMode.calculateFromMacros
          : NutritionInputMode.enterCalories;

  void _setInputMode(CalorieInputMode mode) {
    setState(() => _inputMode = mode);
    // An edit sheet starts in whichever mode the record needs, so its toggling
    // must not overwrite the mode the user picked for adding.
    if (!_isEditing) {
      _modeStore.save(mode);
    }
  }

  void _onQuickAddChanged() {
    widget.onQuickAddChanged?.call(_quickAddController.text);
  }

  /// Applies a [CalculatorKeypad] key press to the expression in
  /// [_quickAddController] (mirrors the old expression-based calculator).
  void _onQuickAddKey(String key) {
    final text = _quickAddController.text;
    if (key == 'C') {
      _quickAddController.text = '';
    } else if (key == '⌫') {
      if (text.isNotEmpty) {
        _quickAddController.text = text.substring(0, text.length - 1);
      }
    } else {
      _quickAddController.text = text + key;
    }
  }

  void _submitQuickAdd() {
    final expression = _quickAddController.text.trim();

    if (expression.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a calorie value'),
          backgroundColor: DangerColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.isSubmitting) {
      return;
    }

    widget.onSubmit(CalorieCalculatorResult(
      calories: ExpressionExecutor.execute(expression),
      expression: expression,
    ));
  }

  void _submitNutrition(NutritionResult result) {
    if (widget.isSubmitting) {
      return;
    }

    widget.onSubmit(CalorieCalculatorResult(
      calories: result.calories,
      weightGrams: result.weightGrams,
      proteinGrams: result.proteinGrams,
      fatGrams: result.fatGrams,
      carbGrams: result.carbGrams,
    ));
  }

  /// The nutrition calculator works in per-100g terms, so an edited record's
  /// absolute values have to be scaled back by its weight to prefill it.
  double? _per100g(double? value) {
    final weight = widget.initialWeightGrams;
    if (value == null || weight == null || weight <= 0) {
      return null;
    }
    return double.parse((value / weight * 100).toStringAsFixed(1));
  }

  static String _formatNumber(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorSheet(
      header: widget.header,
      children: [
        _ModeToggle(mode: _inputMode, onChanged: _setInputMode),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )
        else
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _inputMode == CalorieInputMode.quickAdd
                ? _buildQuickAddMode()
                : _buildNutritionMode(),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildQuickAddMode() {
    return Column(
      key: const ValueKey('quickAdd'),
      children: [
        _QuickAddField(controller: _quickAddController, onSubmit: _submitQuickAdd),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _quickAddController,
            builder: (context, value, _) => CalculatorKeypad(
              showOperators: true,
              canSubmit: value.text.trim().isNotEmpty,
              submitLabel: widget.submitLabel,
              onKey: _onQuickAddKey,
              onSubmit: _submitQuickAdd,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionMode() {
    return NutritionCalculatorWidget(
      key: const ValueKey('nutrition'),
      onSubmit: _submitNutrition,
      submitLabel: widget.submitLabel,
      inputMode: _nutritionMode,
      onModeChanged: (mode) => _setInputMode(
        mode == NutritionInputMode.calculateFromMacros
            ? CalorieInputMode.fromMacros
            : CalorieInputMode.enterCalories,
      ),
      initialWeight: widget.initialWeightGrams,
      initialCaloriesPer100g: _per100g(widget.initialCalories),
      initialProteinPer100g: _per100g(widget.initialProteinGrams),
      initialFatPer100g: _per100g(widget.initialFatGrams),
      initialCarbsPer100g: _per100g(widget.initialCarbGrams),
    );
  }
}

/// Quick Add / Enter Calories / From Macros selector.
class _ModeToggle extends StatelessWidget {
  final CalorieInputMode mode;
  final ValueChanged<CalorieInputMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: appColors.surfaceSubtle
            .withValues(alpha: CustomTheme.surfaceOpacity),
        shape: AppCard.squircleBorder(radius: 10),
      ),
      child: Row(
        children: [
          Expanded(
            child: ModeButton(
              label: 'Quick Add',
              icon: Icons.bolt,
              isSelected: mode == CalorieInputMode.quickAdd,
              onTap: () => onChanged(CalorieInputMode.quickAdd),
            ),
          ),
          Expanded(
            child: ModeButton(
              label: 'Enter Calories',
              icon: Icons.edit,
              isSelected: mode == CalorieInputMode.enterCalories,
              onTap: () => onChanged(CalorieInputMode.enterCalories),
            ),
          ),
          Expanded(
            child: ModeButton(
              label: 'From Macros',
              icon: Icons.calculate,
              isSelected: mode == CalorieInputMode.fromMacros,
              onTap: () => onChanged(CalorieInputMode.fromMacros),
            ),
          ),
        ],
      ),
    );
  }
}

/// The single `+ … kcal` field of quick-add mode.
class _QuickAddField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _QuickAddField({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: appColors.surfaceSubtle,
        shape: AppCard.squircleBorder(radius: 8),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        autofocus: false,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onSubmit(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 16,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: '0',
          hintStyle: TextStyle(
            color: appColors.textTertiary,
            fontSize: 20,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              '+',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: SuccessColor,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 32),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'kcal',
              style: TextStyle(
                fontSize: 14,
                color: appColors.textSecondary,
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 48),
        ),
      ),
    );
  }
}
