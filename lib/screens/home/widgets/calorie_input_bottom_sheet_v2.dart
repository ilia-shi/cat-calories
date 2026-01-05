import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/models/waking_period_model.dart';
import 'package:cat_calories/ui/colors.dart';
import 'package:cat_calories/ui/widgets/calculator_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ui/widgets/nutrition_calculator_widget.dart';

/// Input mode for the calorie input bottom sheet
enum CalorieInputMode {
  /// Simple mode - just enter calories quickly
  simple,
  /// Detailed mode - enter weight and nutritional info per 100g
  detailed,
}

/// Keys for SharedPreferences
class _PrefsKeys {
  static const String inputMode = 'calorie_input_mode';
  static const String nutritionCalcMode = 'nutrition_calc_mode';
}

class CalorieInputBottomSheetV2 extends StatefulWidget {
  final WakingPeriodModel wakingPeriod;
  final List<CalorieItemModel> calorieItems;

  const CalorieInputBottomSheetV2({
    Key? key,
    required this.wakingPeriod,
    required this.calorieItems,
  }) : super(key: key);

  @override
  State<CalorieInputBottomSheetV2> createState() => _CalorieInputBottomSheetV2State();
}

class _CalorieInputBottomSheetV2State extends State<CalorieInputBottomSheetV2> {
  late final TextEditingController _simpleController;
  CalorieInputMode _inputMode = CalorieInputMode.simple;
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

      if (savedMode != null && mounted) {
        setState(() {
          _inputMode = savedMode == 'detailed'
              ? CalorieInputMode.detailed
              : CalorieInputMode.simple;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
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
      await prefs.setString(
        _PrefsKeys.inputMode,
        mode == CalorieInputMode.detailed ? 'detailed' : 'simple',
      );
    } catch (e) {
      // Silently fail - saving preference is not critical
      debugPrint('Failed to save input mode preference: $e');
    }
  }

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

  void _onCalorieItemCreated(CalorieItemModel calorieItem) {
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              _buildModeToggle(isDarkMode),
              const SizedBox(height: 8),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )
              else
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _inputMode == CalorieInputMode.simple
                      ? _buildSimpleMode(isDarkMode)
                      : _buildDetailedMode(isDarkMode),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildModeToggle(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Quick Add',
              icon: Icons.bolt,
              isSelected: _inputMode == CalorieInputMode.simple,
              onTap: () => _setInputMode(CalorieInputMode.simple),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'With Nutrition',
              icon: Icons.restaurant_menu,
              isSelected: _inputMode == CalorieInputMode.detailed,
              onTap: () => _setInputMode(CalorieInputMode.detailed),
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
          child: CalculatorWidget(
            controller: _simpleController,
            onPressed: _submitSimpleCalories,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleInputField(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(8),
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
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          border: InputBorder.none,
          hintText: '0',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 24,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              '+',
              style: TextStyle(
                fontSize: 24,
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
                fontSize: 16,
                color: Colors.grey[600],
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
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}