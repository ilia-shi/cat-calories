import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum representing the different input fields in the nutrition calculator
enum NutritionField {
  weight,
  calories,
  protein,
  fat,
  carbs,
}

/// Extension to provide display names and units for nutrition fields
extension NutritionFieldExtension on NutritionField {
  String get label {
    switch (this) {
      case NutritionField.weight:
        return 'Weight';
      case NutritionField.calories:
        return 'Calories';
      case NutritionField.protein:
        return 'Protein';
      case NutritionField.fat:
        return 'Fat';
      case NutritionField.carbs:
        return 'Carbs';
    }
  }

  String get unit {
    switch (this) {
      case NutritionField.weight:
        return 'g';
      case NutritionField.calories:
        return 'kcal';
      case NutritionField.protein:
      case NutritionField.fat:
      case NutritionField.carbs:
        return 'g';
    }
  }

  String get shortLabel {
    switch (this) {
      case NutritionField.weight:
        return 'W';
      case NutritionField.calories:
        return 'C';
      case NutritionField.protein:
        return 'P';
      case NutritionField.fat:
        return 'F';
      case NutritionField.carbs:
        return 'K';
    }
  }

  IconData get icon {
    switch (this) {
      case NutritionField.weight:
        return Icons.scale;
      case NutritionField.calories:
        return Icons.local_fire_department;
      case NutritionField.protein:
        return Icons.fitness_center;
      case NutritionField.fat:
        return Icons.water_drop;
      case NutritionField.carbs:
        return Icons.grain;
    }
  }

  Color get color {
    switch (this) {
      case NutritionField.weight:
        return Colors.blueGrey;
      case NutritionField.calories:
        return Colors.orange;
      case NutritionField.protein:
        return Colors.red;
      case NutritionField.fat:
        return Colors.amber;
      case NutritionField.carbs:
        return Colors.green;
    }
  }
}

/// Input mode for the calculator
enum NutritionInputMode {
  /// User enters calories directly (weight + calories required)
  enterCalories,
  /// Calories calculated from macros (weight + protein + fat + carbs required)
  calculateFromMacros,
}

/// Keys for SharedPreferences
class _NutritionPrefsKeys {
  static const String calcMode = 'nutrition_calc_mode';
}

/// Model representing the calculated nutrition values (normalized to actual portion)
class NutritionResult {
  final double weightGrams;
  final double calories;
  final double? proteinGrams;
  final double? fatGrams;
  final double? carbGrams;

  const NutritionResult({
    required this.weightGrams,
    required this.calories,
    this.proteinGrams,
    this.fatGrams,
    this.carbGrams,
  });

  @override
  String toString() {
    return 'NutritionResult(weight: $weightGrams, calories: $calories, '
        'protein: $proteinGrams, fat: $fatGrams, carbs: $carbGrams)';
  }
}

/// A calculator widget for entering nutritional information without using the keyboard.
///
/// All nutritional values (calories, protein, fat, carbs) are entered as "per 100g" values.
/// The widget calculates the actual values based on the weight entered.
class NutritionCalculatorWidget extends StatefulWidget {
  /// Callback when the user submits valid nutrition data
  final void Function(NutritionResult result) onSubmit;

  /// Optional initial values (per 100g, except weight which is actual grams)
  final double? initialWeight;
  final double? initialCaloriesPer100g;
  final double? initialProteinPer100g;
  final double? initialFatPer100g;
  final double? initialCarbsPer100g;

  const NutritionCalculatorWidget({
    Key? key,
    required this.onSubmit,
    this.initialWeight,
    this.initialCaloriesPer100g,
    this.initialProteinPer100g,
    this.initialFatPer100g,
    this.initialCarbsPer100g,
  }) : super(key: key);

  @override
  State<NutritionCalculatorWidget> createState() => _NutritionCalculatorWidgetState();
}

class _NutritionCalculatorWidgetState extends State<NutritionCalculatorWidget> {
  /// Current input mode
  NutritionInputMode _inputMode = NutritionInputMode.enterCalories;

  /// Currently selected field
  NutritionField _selectedField = NutritionField.weight;

  /// Text controllers for each field
  late final Map<NutritionField, TextEditingController> _controllers;

  /// Track which fields have been edited
  final Set<NutritionField> _editedFields = {};

  @override
  void initState() {
    super.initState();
    _controllers = {
      NutritionField.weight: TextEditingController(
        text: widget.initialWeight?.toString() ?? '',
      ),
      NutritionField.calories: TextEditingController(
        text: widget.initialCaloriesPer100g?.toString() ?? '',
      ),
      NutritionField.protein: TextEditingController(
        text: widget.initialProteinPer100g?.toString() ?? '',
      ),
      NutritionField.fat: TextEditingController(
        text: widget.initialFatPer100g?.toString() ?? '',
      ),
      NutritionField.carbs: TextEditingController(
        text: widget.initialCarbsPer100g?.toString() ?? '',
      ),
    };

    // Mark initial values as edited
    if (widget.initialWeight != null) _editedFields.add(NutritionField.weight);
    if (widget.initialCaloriesPer100g != null) _editedFields.add(NutritionField.calories);
    if (widget.initialProteinPer100g != null) _editedFields.add(NutritionField.protein);
    if (widget.initialFatPer100g != null) _editedFields.add(NutritionField.fat);
    if (widget.initialCarbsPer100g != null) _editedFields.add(NutritionField.carbs);

    _loadSavedCalcMode();
  }

  /// Load the previously saved calculation mode
  Future<void> _loadSavedCalcMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_NutritionPrefsKeys.calcMode);

      if (savedMode != null && mounted) {
        setState(() {
          _inputMode = savedMode == 'fromMacros'
              ? NutritionInputMode.calculateFromMacros
              : NutritionInputMode.enterCalories;
        });
      }
    } catch (e) {
      // If loading fails, just use default
      debugPrint('Failed to load calc mode preference: $e');
    }
  }

  /// Save the selected calculation mode
  Future<void> _saveCalcMode(NutritionInputMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _NutritionPrefsKeys.calcMode,
        mode == NutritionInputMode.calculateFromMacros ? 'fromMacros' : 'enterCalories',
      );
    } catch (e) {
      debugPrint('Failed to save calc mode preference: $e');
    }
  }

  /// Update the calculation mode and persist the choice
  void _setCalcMode(NutritionInputMode mode) {
    setState(() {
      _inputMode = mode;
      // If switching to fromMacros and currently on calories field, move to weight
      if (mode == NutritionInputMode.calculateFromMacros &&
          _selectedField == NutritionField.calories) {
        _selectedField = NutritionField.weight;
      }
    });
    _saveCalcMode(mode);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Get the current controller based on selected field
  TextEditingController get _currentController => _controllers[_selectedField]!;

  /// Parse a field value, returns null if invalid
  double? _parseField(NutritionField field) {
    final text = _controllers[field]!.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  /// Calculate calories from macros (per 100g)
  /// Protein: 4 kcal/g, Carbs: 4 kcal/g, Fat: 9 kcal/g
  double _calculateCaloriesFromMacros() {
    final protein = _parseField(NutritionField.protein) ?? 0;
    final fat = _parseField(NutritionField.fat) ?? 0;
    final carbs = _parseField(NutritionField.carbs) ?? 0;
    return (protein * 4) + (carbs * 4) + (fat * 9);
  }

  /// Check if the current input is valid for submission
  bool _isValidInput() {
    final weight = _parseField(NutritionField.weight);
    if (weight == null || weight <= 0) return false;

    if (_inputMode == NutritionInputMode.enterCalories) {
      final calories = _parseField(NutritionField.calories);
      return calories != null && calories >= 0;
    } else {
      // Calculate from macros mode - need at least one macro
      final protein = _parseField(NutritionField.protein);
      final fat = _parseField(NutritionField.fat);
      final carbs = _parseField(NutritionField.carbs);
      return (protein != null && protein >= 0) ||
          (fat != null && fat >= 0) ||
          (carbs != null && carbs >= 0);
    }
  }

  /// Get validation message for current state
  String? _getValidationMessage() {
    final weight = _parseField(NutritionField.weight);
    if (weight == null || weight <= 0) {
      return 'Weight is required';
    }

    if (_inputMode == NutritionInputMode.enterCalories) {
      final calories = _parseField(NutritionField.calories);
      if (calories == null) {
        return 'Calories per 100g is required';
      }
    } else {
      final protein = _parseField(NutritionField.protein);
      final fat = _parseField(NutritionField.fat);
      final carbs = _parseField(NutritionField.carbs);
      if (protein == null && fat == null && carbs == null) {
        return 'Enter at least one macro (P/F/C)';
      }
    }

    return null;
  }

  /// Calculate the final nutrition result
  NutritionResult? _calculateResult() {
    final weight = _parseField(NutritionField.weight);
    if (weight == null || weight <= 0) return null;

    final ratio = weight / 100.0;

    double caloriesPer100g;
    if (_inputMode == NutritionInputMode.calculateFromMacros) {
      caloriesPer100g = _calculateCaloriesFromMacros();
    } else {
      caloriesPer100g = _parseField(NutritionField.calories) ?? 0;
    }

    final proteinPer100g = _parseField(NutritionField.protein);
    final fatPer100g = _parseField(NutritionField.fat);
    final carbsPer100g = _parseField(NutritionField.carbs);

    return NutritionResult(
      weightGrams: weight,
      calories: caloriesPer100g * ratio,
      proteinGrams: proteinPer100g != null ? proteinPer100g * ratio : null,
      fatGrams: fatPer100g != null ? fatPer100g * ratio : null,
      carbGrams: carbsPer100g != null ? carbsPer100g * ratio : null,
    );
  }

  /// Handle calculator button press
  void _onKeyPress(String key) {
    setState(() {
      _editedFields.add(_selectedField);

      final controller = _currentController;
      final currentText = controller.text;

      switch (key) {
        case 'C':
          controller.text = '';
          break;
        case '⌫':
          if (currentText.isNotEmpty) {
            controller.text = currentText.substring(0, currentText.length - 1);
          }
          break;
        case '.':
        // Only add decimal if not already present
          if (!currentText.contains('.')) {
            controller.text = currentText + '.';
          }
          break;
        case '→':
        // Move to next field
          _moveToNextField();
          break;
        default:
        // Number key
          controller.text = currentText + key;
      }
    });
  }

  /// Move to the next logical field
  void _moveToNextField() {
    final fields = _getVisibleFields();
    final currentIndex = fields.indexOf(_selectedField);
    if (currentIndex < fields.length - 1) {
      setState(() {
        _selectedField = fields[currentIndex + 1];
      });
    }
  }

  /// Get the list of visible fields based on input mode
  List<NutritionField> _getVisibleFields() {
    if (_inputMode == NutritionInputMode.enterCalories) {
      return [
        NutritionField.weight,
        NutritionField.calories,
        NutritionField.protein,
        NutritionField.fat,
        NutritionField.carbs,
      ];
    } else {
      return [
        NutritionField.weight,
        NutritionField.protein,
        NutritionField.fat,
        NutritionField.carbs,
      ];
    }
  }

  /// Handle submit
  void _onSubmit() {
    if (!_isValidInput()) {
      final message = _getValidationMessage();
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final result = _calculateResult();
    if (result != null) {
      widget.onSubmit(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode toggle
        _buildModeToggle(isDarkMode),
        const SizedBox(height: 12),

        // Field selector tabs
        _buildFieldSelector(isDarkMode),
        const SizedBox(height: 12),

        // Current field display
        _buildCurrentFieldDisplay(isDarkMode),
        const SizedBox(height: 8),

        // Summary panel showing all values
        _buildSummaryPanel(isDarkMode),
        const SizedBox(height: 8),

        // Calculator keypad
        _buildKeypad(isPortrait, isDarkMode),
      ],
    );
  }

  Widget _buildModeToggle(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Enter Calories',
              icon: Icons.edit,
              isSelected: _inputMode == NutritionInputMode.enterCalories,
              onTap: () => _setCalcMode(NutritionInputMode.enterCalories),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'From Macros',
              icon: Icons.calculate,
              isSelected: _inputMode == NutritionInputMode.calculateFromMacros,
              onTap: () => _setCalcMode(NutritionInputMode.calculateFromMacros),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSelector(bool isDarkMode) {
    final fields = _getVisibleFields();

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fields.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final field = fields[index];
          final isSelected = field == _selectedField;
          final hasValue = _controllers[field]!.text.isNotEmpty;
          final isRequired = _isFieldRequired(field);

          return _FieldSelectorChip(
            field: field,
            isSelected: isSelected,
            hasValue: hasValue,
            isRequired: isRequired,
            onTap: () => setState(() => _selectedField = field),
          );
        },
      ),
    );
  }

  bool _isFieldRequired(NutritionField field) {
    if (field == NutritionField.weight) return true;
    if (_inputMode == NutritionInputMode.enterCalories) {
      return field == NutritionField.calories;
    } else {
      // In calculate mode, at least one macro is required
      return field == NutritionField.protein ||
          field == NutritionField.fat ||
          field == NutritionField.carbs;
    }
  }

  Widget _buildCurrentFieldDisplay(bool isDarkMode) {
    final controller = _currentController;
    final field = _selectedField;
    final isPerHundredGrams = field != NutritionField.weight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: field.color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(field.icon, color: field.color, size: 20),
              const SizedBox(width: 8),
              Text(
                field.label,
                style: TextStyle(
                  color: field.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (isPerHundredGrams) ...[
                const SizedBox(width: 4),
                Text(
                  '(per 100g)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                controller.text.isEmpty ? '0' : controller.text,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                field.unit,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel(bool isDarkMode) {
    final result = _calculateResult();
    final weight = _parseField(NutritionField.weight);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Calculated Values',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              if (weight != null && weight > 0)
                Text(
                  'for ${weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1)}g portion',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SummaryItem(
                label: 'Cal',
                value: result?.calories,
                unit: 'kcal',
                color: NutritionField.calories.color,
                isCalculated: _inputMode == NutritionInputMode.calculateFromMacros,
              ),
              _SummaryItem(
                label: 'P',
                value: result?.proteinGrams,
                unit: 'g',
                color: NutritionField.protein.color,
              ),
              _SummaryItem(
                label: 'F',
                value: result?.fatGrams,
                unit: 'g',
                color: NutritionField.fat.color,
              ),
              _SummaryItem(
                label: 'C',
                value: result?.carbGrams,
                unit: 'g',
                color: NutritionField.carbs.color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(bool isPortrait, bool isDarkMode) {
    final keys = [
      ['1', '2', '3', '→'],
      ['4', '5', '6', '⌫'],
      ['7', '8', '9', 'C'],
      ['.', '0', 'OK'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: keys.map((row) {
          return Row(
            children: row.map((key) {
              final isOk = key == 'OK';
              final isValid = _isValidInput();

              return Expanded(
                flex: isOk ? 2 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _KeypadButton(
                    label: key,
                    onTap: isOk ? _onSubmit : () => _onKeyPress(key),
                    isOk: isOk,
                    isValid: isValid,
                    isDarkMode: isDarkMode,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// Helper Widgets
// ============================================================================

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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

class _FieldSelectorChip extends StatelessWidget {
  final NutritionField field;
  final bool isSelected;
  final bool hasValue;
  final bool isRequired;
  final VoidCallback onTap;

  const _FieldSelectorChip({
    required this.field,
    required this.isSelected,
    required this.hasValue,
    required this.isRequired,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? field.color.withOpacity(0.2)
              : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? field.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              field.icon,
              size: 18,
              color: isSelected ? field.color : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              field.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? field.color : Colors.grey[600],
              ),
            ),
            if (hasValue) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.green[600],
              ),
            ] else if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final Color color;
  final bool isCalculated;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.isCalculated = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value != null
        ? value!.toStringAsFixed(value!.truncateToDouble() == value ? 0 : 1)
        : '-';

    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isCalculated)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 10,
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: value != null ? null : Colors.grey[500],
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOk;
  final bool isValid;
  final bool isDarkMode;

  const _KeypadButton({
    required this.label,
    required this.onTap,
    required this.isOk,
    required this.isValid,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (isOk) {
      backgroundColor = isValid ? Colors.green : Colors.grey;
      textColor = Colors.white;
    } else if (label == 'C') {
      backgroundColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
    } else if (label == '⌫') {
      backgroundColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
    } else if (label == '→') {
      backgroundColor = Colors.blue.withOpacity(0.1);
      textColor = Colors.blue;
    } else {
      backgroundColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
      textColor = isDarkMode ? Colors.white : Colors.black87;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: label == '⌫'
              ? Icon(Icons.backspace_outlined, color: textColor, size: 22)
              : label == '→'
              ? Icon(Icons.arrow_forward, color: textColor, size: 22)
              : Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}