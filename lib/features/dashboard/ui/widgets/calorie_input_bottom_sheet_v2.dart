import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/theme/theme.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_keypad.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cat_calories/common/widgets/mode_button.dart';
import 'package:cat_calories/common/widgets/nutrition_calculator_widget.dart';

/// Input mode for the calorie input bottom sheet
enum CalorieInputMode {
  /// Simple mode - just enter calories quickly
  quickAdd,

  /// Nutrition calculator, entering calories per 100g directly
  enterCalories,

  /// Nutrition calculator, calories computed from macros
  fromMacros,
}

/// Keys for SharedPreferences
class _PrefsKeys {
  static const String inputMode = 'calorie_input_mode';
  static const String nutritionCalcMode = 'nutrition_calc_mode';
}

class CalorieInputBottomSheetV2 extends StatefulWidget {
  final WakingPeriod wakingPeriod;
  final List<CalorieRecord> calorieItems;

  const CalorieInputBottomSheetV2({
    Key? key,
    required this.wakingPeriod,
    required this.calorieItems,
  }) : super(key: key);

  @override
  State<CalorieInputBottomSheetV2> createState() =>
      _CalorieInputBottomSheetV2State();
}

class _CalorieInputBottomSheetV2State extends State<CalorieInputBottomSheetV2> {
  late final TextEditingController _simpleController;
  CalorieInputMode _inputMode = CalorieInputMode.quickAdd;
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simpleController = TextEditingController();
    _simpleController.addListener(_onSimpleInputChanged);
    _loadSavedMode();
  }

  /// Load the previously saved input mode from SharedPreferences
  Future<void> _loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_PrefsKeys.inputMode);

      CalorieInputMode? mode;
      switch (savedMode) {
        case 'simple':
          mode = CalorieInputMode.quickAdd;
          break;
        case 'enterCalories':
          mode = CalorieInputMode.enterCalories;
          break;
        case 'fromMacros':
          mode = CalorieInputMode.fromMacros;
          break;
        case 'detailed':
          // Legacy value: resolve the nutrition sub-mode from its own pref.
          mode =
              prefs.getString(_PrefsKeys.nutritionCalcMode) == 'fromMacros'
                  ? CalorieInputMode.fromMacros
                  : CalorieInputMode.enterCalories;
          break;
      }

      if (mounted) {
        setState(() {
          if (mode != null) _inputMode = mode;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If loading fails, just use default and continue
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Save the selected input mode to SharedPreferences
  Future<void> _saveMode(CalorieInputMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_PrefsKeys.inputMode, _modeToPref(mode));
      // Keep the nutrition sub-mode pref in sync for the calculator default.
      if (mode != CalorieInputMode.quickAdd) {
        await prefs.setString(
          _PrefsKeys.nutritionCalcMode,
          mode == CalorieInputMode.fromMacros ? 'fromMacros' : 'enterCalories',
        );
      }
    } catch (e) {
      // Silently fail - saving preference is not critical
      debugPrint('Failed to save input mode preference: $e');
    }
  }

  String _modeToPref(CalorieInputMode mode) {
    switch (mode) {
      case CalorieInputMode.quickAdd:
        return 'simple';
      case CalorieInputMode.enterCalories:
        return 'enterCalories';
      case CalorieInputMode.fromMacros:
        return 'fromMacros';
    }
  }

  /// The nutrition calculator mode corresponding to the current input mode.
  NutritionInputMode get _nutritionMode =>
      _inputMode == CalorieInputMode.fromMacros
          ? NutritionInputMode.calculateFromMacros
          : NutritionInputMode.enterCalories;

  /// Update the input mode and persist the choice
  void _setInputMode(CalorieInputMode mode) {
    setState(() => _inputMode = mode);
    _saveMode(mode);
  }

  @override
  void dispose() {
    _simpleController.removeListener(_onSimpleInputChanged);
    _simpleController.dispose();
    super.dispose();
  }

  void _onSimpleInputChanged() {
    context.read<HomeBloc>().add(CaloriePreparedEvent(_simpleController.text));
  }

  void _submitSimpleCalories() {
    final expression = _simpleController.text.trim();

    if (expression.isEmpty) {
      _showSnackBar('Please enter a calorie value', isError: true);
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    context.read<HomeBloc>().add(
          CreatingCalorieItemEvent(
            expression,
            widget.wakingPeriod,
            widget.calorieItems,
            _onCalorieItemCreated,
          ),
        );
  }

  void _submitNutritionCalories(NutritionResult result) {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    // Use the new event that includes nutrition data
    context.read<HomeBloc>().add(
          CreatingCalorieItemWithNutritionEvent(
            calories: result.calories,
            wakingPeriod: widget.wakingPeriod,
            calorieItems: widget.calorieItems,
            weightGrams: result.weightGrams,
            proteinGrams: result.proteinGrams,
            fatGrams: result.fatGrams,
            carbGrams: result.carbGrams,
            callback: _onCalorieItemCreated,
          ),
        );
  }

  void _onCalorieItemCreated(CalorieRecord calorieItem) {
    _simpleController.clear();

    setState(() {
      _isSubmitting = false;
    });

    Navigator.of(context).pop();

    // Build a summary message
    String message = '${calorieItem.value.toStringAsFixed(0)} kcal added';
    if (calorieItem.weightGrams != null) {
      message = '${calorieItem.weightGrams!.toStringAsFixed(0)}g • $message';
    }

    _showSnackBar(message);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? DangerColor : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CalculatorSheet(
      children: [
        _buildModeToggle(isDarkMode),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )
        else
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _inputMode == CalorieInputMode.quickAdd
                ? _buildSimpleMode(isDarkMode)
                : _buildDetailedMode(isDarkMode),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildModeToggle(bool isDarkMode) {
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
              isSelected: _inputMode == CalorieInputMode.quickAdd,
              onTap: () => _setInputMode(CalorieInputMode.quickAdd),
            ),
          ),
          Expanded(
            child: ModeButton(
              label: 'Enter Calories',
              icon: Icons.edit,
              isSelected: _inputMode == CalorieInputMode.enterCalories,
              onTap: () => _setInputMode(CalorieInputMode.enterCalories),
            ),
          ),
          Expanded(
            child: ModeButton(
              label: 'From Macros',
              icon: Icons.calculate,
              isSelected: _inputMode == CalorieInputMode.fromMacros,
              onTap: () => _setInputMode(CalorieInputMode.fromMacros),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMode(bool isDarkMode) {
    return Column(
      key: const ValueKey('simple'),
      children: [
        _buildSimpleInputField(isDarkMode),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _simpleController,
            builder: (context, value, _) => CalculatorKeypad(
              showOperators: true,
              canSubmit: value.text.trim().isNotEmpty,
              onKey: _onSimpleKey,
              onSubmit: _submitSimpleCalories,
            ),
          ),
        ),
      ],
    );
  }

  /// Applies a [CalculatorKeypad] key press to the expression in
  /// [_simpleController] (mirrors the old expression-based calculator).
  void _onSimpleKey(String key) {
    final text = _simpleController.text;
    if (key == 'C') {
      _simpleController.text = '';
    } else if (key == '⌫') {
      if (text.isNotEmpty) {
        _simpleController.text = text.substring(0, text.length - 1);
      }
    } else {
      _simpleController.text = text + key;
    }
  }

  Widget _buildSimpleInputField(bool isDarkMode) {
    final appColors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: appColors.surfaceSubtle,
        shape: AppCard.squircleBorder(radius: 8),
      ),
      child: TextField(
        controller: _simpleController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        autofocus: false,
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

  Widget _buildDetailedMode(bool isDarkMode) {
    return Padding(
      key: const ValueKey('detailed'),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: NutritionCalculatorWidget(
        onSubmit: _submitNutritionCalories,
        inputMode: _nutritionMode,
        onModeChanged: (mode) => _setInputMode(
          mode == NutritionInputMode.calculateFromMacros
              ? CalorieInputMode.fromMacros
              : CalorieInputMode.enterCalories,
        ),
      ),
    );
  }
}
