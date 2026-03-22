import 'package:cat_calories/features/products/domain/product_model.dart';
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
  final ProductModel product;
  final void Function(ProductWeightResult result) onSubmit;

  const ProductWeightInputSheet({
    Key? key,
    required this.product,
    required this.onSubmit,
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
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  double? get _calculatedCalories {
    final weight = _currentWeight;
    if (weight == null || weight <= 0) return null;
    return widget.product.calculateCalories(weight);
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
    if (!_isValidInput || _isSubmitting) return;

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
    if (_isSubmitting || !widget.product.hasPackageWeight) return;

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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildProductHeader(isDarkMode),
            const SizedBox(height: 8),
            _buildWeightDisplay(isDarkMode),
            const SizedBox(height: 8),
            _buildNutritionSummary(isDarkMode),
            if (widget.product.hasPackageWeight) ...[
              const SizedBox(height: 8),
              _buildEntirePackageButton(isDarkMode),
            ],
            const SizedBox(height: 16),
            _buildKeypad(isDarkMode),
            const SizedBox(height: 8),
          ],
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

  Widget _buildProductHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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

  Widget _buildWeightDisplay(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.scale,
            size: 24,
            color: Colors.blueGrey[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _controller.text.isEmpty ? '' : _controller.text,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: _controller.text.isEmpty ? Colors.grey[400] : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            'g',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(bool isDarkMode) {
    final weight = _currentWeight ?? 0;
    final calories = weight > 0 ? widget.product.calculateCalories(weight) : null;
    final protein = weight > 0 ? widget.product.calculateProtein(weight) : null;
    final fat = weight > 0 ? widget.product.calculateFat(weight) : null;
    final carbs = weight > 0 ? widget.product.calculateCarbs(weight) : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
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
          'Eat entire package (${packageWeight.toStringAsFixed(0)}g • $packageCalories kcal)',
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDarkMode) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
      ['.', 'OK'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: keys.map((row) {
          return Row(
            children: row.map((key) {
              final isOk = key == 'OK';
              final isValid = _isValidInput;
              final flex = isOk ? 2 : 1;

              return Expanded(
                flex: flex,
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
      backgroundColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red;
    } else if (label == '⌫') {
      backgroundColor = Colors.orange.withValues(alpha: 0.1);
      textColor = Colors.orange;
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