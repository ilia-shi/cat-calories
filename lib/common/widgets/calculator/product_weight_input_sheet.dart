import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_field_display.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_keypad.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_sheet.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:flutter/material.dart';

/// Result from the product weight input dialog
class ProductWeightResult {
  final double weightGrams;
  final double calories;
  final double? proteinGrams;
  final double? fatGrams;
  final double? carbGrams;
  final bool isEntirePackage;

  const ProductWeightResult({
    required this.weightGrams,
    required this.calories,
    this.proteinGrams,
    this.fatGrams,
    this.carbGrams,
    this.isEntirePackage = false,
  });
}

/// A bottom sheet for entering product weight using a calculator-style keypad
class ProductWeightInputSheet extends StatefulWidget {
  final Product product;
  final void Function(ProductWeightResult result) onSubmit;

  /// Wording of the shortcut that takes the whole package weight. Defaults to
  /// the eating flow; cooking passes its own verb.
  final String entirePackageLabel;

  const ProductWeightInputSheet({
    Key? key,
    required this.product,
    required this.onSubmit,
    this.entirePackageLabel = 'Eat entire package',
  }) : super(key: key);

  @override
  State<ProductWeightInputSheet> createState() =>
      _ProductWeightInputSheetState();
}

class _ProductWeightInputSheetState extends State<ProductWeightInputSheet> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _currentWeight {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  bool get _isValidInput {
    final weight = _currentWeight;
    return weight != null && weight > 0 && widget.product.hasNutrition;
  }

  void _onKeyPress(String key) {
    final currentText = _controller.text;

    if (key == 'C') {
      _controller.text = '';
    } else if (key == '⌫') {
      if (currentText.isNotEmpty) {
        _controller.text = currentText.substring(0, currentText.length - 1);
      }
    } else if (key == '.') {
      if (!currentText.contains('.')) {
        // Prepend 0 if text is empty
        if (currentText.isEmpty) {
          _controller.text = '0.';
        } else {
          _controller.text = currentText + key;
        }
      }
    } else {
      _controller.text = currentText + key;
    }
    setState(() {});
  }

  void _onSubmit() {
    if (!_isValidInput || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    final weight = _currentWeight!;
    final result = ProductWeightResult(
      weightGrams: weight,
      calories: widget.product.calculateCalories(weight) ?? 0,
      proteinGrams: widget.product.calculateProtein(weight),
      fatGrams: widget.product.calculateFat(weight),
      carbGrams: widget.product.calculateCarbs(weight),
      isEntirePackage: false,
    );

    widget.onSubmit(result);
  }

  void _onEatEntirePackage() {
    if (_isSubmitting || !widget.product.hasPackageWeight) {
      return;
    }

    setState(() => _isSubmitting = true);

    final weight = widget.product.packageWeightGrams!;
    final result = ProductWeightResult(
      weightGrams: weight,
      calories: widget.product.calculateCalories(weight) ?? 0,
      proteinGrams: widget.product.calculateProtein(weight),
      fatGrams: widget.product.calculateFat(weight),
      carbGrams: widget.product.calculateCarbs(weight),
      isEntirePackage: true,
    );

    widget.onSubmit(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CalculatorSheet(
      header: _buildProductHeader(),
      children: [
        const SizedBox(height: 8),
        _buildWeightDisplay(),
        const SizedBox(height: 8),
        _buildNutritionSummary(),
        if (widget.product.hasPackageWeight) ...[
          const SizedBox(height: 8),
          _buildEntirePackageButton(isDarkMode),
        ],
        const SizedBox(height: 16),
        CalculatorKeypad(
          canSubmit: _isValidInput,
          onKey: _onKeyPress,
          onSubmit: _onSubmit,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProductHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: ShapeDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: AppCard.squircleBorder(radius: 12),
            ),
            child: const Icon(
              Icons.restaurant,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.product.hasNutrition)
                  Text(
                    '${widget.product.caloriesPer100g?.toStringAsFixed(0) ?? '-'} kcal/100g',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightDisplay() {
    return CalculatorFieldDisplay(
      icon: Icons.scale,
      label: 'Weight',
      color: Colors.blueGrey,
      value: _controller.text.isEmpty ? '0' : _controller.text,
      unit: 'g',
      isPlaceholder: _controller.text.isEmpty,
    );
  }

  Widget _buildNutritionSummary() {
    final appColors = AppColors.of(context);
    final weight = _currentWeight ?? 0;
    final calories = weight > 0 ? widget.product.calculateCalories(weight) : null;
    final protein = weight > 0 ? widget.product.calculateProtein(weight) : null;
    final fat = weight > 0 ? widget.product.calculateFat(weight) : null;
    final carbs = weight > 0 ? widget.product.calculateCarbs(weight) : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: ShapeDecoration(
        color: appColors.surfaceSubtle,
        shape: AppCard.squircleBorder(radius: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NutritionItem(
            label: 'Calories',
            value: calories?.toStringAsFixed(0) ?? '-',
            unit: 'kcal',
            color: Colors.orange,
            isHighlighted: true,
          ),
          _NutritionItem(
            label: 'Protein',
            value: protein?.toStringAsFixed(1) ?? '-',
            unit: 'g',
            color: Colors.red,
          ),
          _NutritionItem(
            label: 'Fat',
            value: fat?.toStringAsFixed(1) ?? '-',
            unit: 'g',
            color: Colors.amber,
          ),
          _NutritionItem(
            label: 'Carbs',
            value: carbs?.toStringAsFixed(1) ?? '-',
            unit: 'g',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildEntirePackageButton(bool isDarkMode) {
    final packageWeight = widget.product.packageWeightGrams!;
    final packageCalories =
        widget.product.calculateCalories(packageWeight)?.toStringAsFixed(0) ??
            '-';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: _onEatEntirePackage,
        icon: const Icon(Icons.inventory_2_outlined),
        label: Text(
          '${widget.entirePackageLabel} '
          '(${packageWeight.toStringAsFixed(0)}g • $packageCalories kcal)',
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: AppCard.squircleBorder(radius: 12),
        ),
      ),
    );
  }

}

class _NutritionItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isHighlighted;

  const _NutritionItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 18 : 16,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
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
    );
  }
}

