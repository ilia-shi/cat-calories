import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories/common/theme/colors.dart';
import 'package:cat_calories/common/widgets/app_card.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_field_display.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_keypad.dart';
import 'package:cat_calories/common/widgets/calculator/calculator_sheet.dart';
import 'package:cat_calories/common/widgets/macro_chips.dart';
import 'package:flutter/material.dart';

class ProportionalEditResult {
  final double weightGrams;
  final double calories;
  final double? proteinGrams;
  final double? fatGrams;
  final double? carbGrams;

  const ProportionalEditResult({
    required this.weightGrams,
    required this.calories,
    this.proteinGrams,
    this.fatGrams,
    this.carbGrams,
  });
}

class ProportionalEditBottomSheet extends StatefulWidget {
  final CalorieRecord item;
  final void Function(ProportionalEditResult result) onSave;

  const ProportionalEditBottomSheet({
    Key? key,
    required this.item,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ProportionalEditBottomSheet> createState() =>
      _ProportionalEditBottomSheetState();
}

class _ProportionalEditBottomSheetState
    extends State<ProportionalEditBottomSheet> {
  String _weightText = '';

  double get _originalWeight => widget.item.weightGrams ?? 0;
  double get _originalCalories => widget.item.value;

  double? get _newWeight =>
      _weightText.isEmpty ? null : double.tryParse(_weightText);

  double get _ratio {
    final nw = _newWeight;
    if (nw == null || nw <= 0 || _originalWeight <= 0) {
      return 0;
    }
    return nw / _originalWeight;
  }

  bool get _isValid =>
      _newWeight != null && _newWeight! > 0 && _originalWeight > 0;

  double? get _newCalories => _isValid ? _originalCalories * _ratio : null;

  double? get _newProtein {
    if (!_isValid || widget.item.proteinGrams == null) {
      return null;
    }
    return widget.item.proteinGrams! * _ratio;
  }

  double? get _newFat {
    if (!_isValid || widget.item.fatGrams == null) {
      return null;
    }
    return widget.item.fatGrams! * _ratio;
  }

  double? get _newCarbs {
    if (!_isValid || widget.item.carbGrams == null) {
      return null;
    }
    return widget.item.carbGrams! * _ratio;
  }

  void _onKeyPress(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _weightText = '';
          break;
        case '⌫':
          if (_weightText.isNotEmpty) {
            _weightText = _weightText.substring(0, _weightText.length - 1);
          }
          break;
        case '.':
          if (!_weightText.contains('.')) {
            _weightText = _weightText.isEmpty ? '0.' : '$_weightText.';
          }
          break;
        default:
          _weightText += key;
      }
    });
  }

  void _onSubmit() {
    if (!_isValid) {
      return;
    }
    widget.onSave(ProportionalEditResult(
      weightGrams: _newWeight!,
      calories: _newCalories!,
      proteinGrams: _newProtein,
      fatGrams: _newFat,
      carbGrams: _newCarbs,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);

    return CalculatorSheet(
      header: _buildHeader(appColors),
      children: [
        const SizedBox(height: 12),
        _buildWeightInput(appColors),
        const SizedBox(height: 8),
        _buildComparison(appColors),
        const SizedBox(height: 8),
        CalculatorKeypad(
          canSubmit: _isValid,
          submitLabel: 'Save',
          submitAccent: Colors.teal,
          onKey: _onKeyPress,
          onSubmit: _onSubmit,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHeader(AppColors appColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              shape: AppCard.squircleBorder(radius: 8),
            ),
            child: const Icon(Icons.scale, color: Colors.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Adjust Weight',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Scale all values proportionally',
                  style: TextStyle(
                    fontSize: 13,
                    color: appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparison(AppColors appColors) {
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: appColors.surfaceSubtle,
        shape: AppCard.squircleBorder(radius: 12),
      ),
      child: Column(
        children: [
          if (item.description != null && item.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                item.description!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: appColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          _buildComparisonRow(
            icon: Icons.local_fire_department,
            color: Colors.orange,
            oldValue: '${_originalCalories.toStringAsFixed(0)} kcal',
            newValue: _newCalories != null
                ? '${_newCalories!.toStringAsFixed(0)} kcal'
                : null,
            appColors: appColors,
          ),
          if (item.proteinGrams != null) ...[
            const SizedBox(height: 6),
            _buildComparisonRow(
              label: 'P',
              color: MacroProteinColor,
              oldValue: '${item.proteinGrams!.toStringAsFixed(0)}g',
              newValue: _newProtein != null
                  ? '${_newProtein!.toStringAsFixed(0)}g'
                  : null,
              appColors: appColors,
            ),
          ],
          if (item.fatGrams != null) ...[
            const SizedBox(height: 6),
            _buildComparisonRow(
              label: 'F',
              color: MacroFatColor,
              oldValue: '${item.fatGrams!.toStringAsFixed(0)}g',
              newValue:
                  _newFat != null ? '${_newFat!.toStringAsFixed(0)}g' : null,
              appColors: appColors,
            ),
          ],
          if (item.carbGrams != null) ...[
            const SizedBox(height: 6),
            _buildComparisonRow(
              label: 'C',
              color: MacroCarbColor,
              oldValue: '${item.carbGrams!.toStringAsFixed(0)}g',
              newValue: _newCarbs != null
                  ? '${_newCarbs!.toStringAsFixed(0)}g'
                  : null,
              appColors: appColors,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonRow({
    IconData? icon,
    String? label,
    required Color color,
    required String oldValue,
    required String? newValue,
    required AppColors appColors,
  }) {
    return Row(
      children: [
        // Label/icon
        SizedBox(
          width: 28,
          child: icon != null
              ? Icon(icon, size: 16, color: color)
              : Align(
                  alignment: Alignment.centerLeft,
                  child: MacroCircle(label: label!, color: color),
                ),
        ),
        // Old value
        Expanded(
          child: Text(
            oldValue,
            style: TextStyle(
              fontSize: 14,
              color: appColors.textSecondary,
            ),
          ),
        ),
        // Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward,
            size: 14,
            color: newValue != null ? Colors.teal : appColors.textDisabled,
          ),
        ),
        // New value
        Expanded(
          child: Text(
            newValue ?? '—',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: newValue != null ? FontWeight.w600 : FontWeight.normal,
              color: newValue != null ? color : appColors.textDisabled,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightInput(AppColors appColors) {
    return CalculatorFieldDisplay(
      icon: Icons.scale,
      label: 'New Weight',
      color: Colors.teal,
      value: _weightText.isEmpty ? '0' : _weightText,
      unit: 'g',
      isPlaceholder: _weightText.isEmpty,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'was ${_originalWeight.toStringAsFixed(0)}g',
            style: TextStyle(
              fontSize: 12,
              color: appColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Opacity(
            opacity: _isValid ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isValid ? '\u00d7${_ratio.toStringAsFixed(1)}' : '\u00d71.0',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
