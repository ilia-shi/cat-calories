import 'package:cat_calories/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories/ui/colors.dart';
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
    if (nw == null || nw <= 0 || _originalWeight <= 0) return 0;
    return nw / _originalWeight;
  }

  bool get _isValid =>
      _newWeight != null && _newWeight! > 0 && _originalWeight > 0;

  double? get _newCalories => _isValid ? _originalCalories * _ratio : null;

  double? get _newProtein {
    if (!_isValid || widget.item.proteinGrams == null) return null;
    return widget.item.proteinGrams! * _ratio;
  }

  double? get _newFat {
    if (!_isValid || widget.item.fatGrams == null) return null;
    return widget.item.fatGrams! * _ratio;
  }

  double? get _newCarbs {
    if (!_isValid || widget.item.carbGrams == null) return null;
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
    if (!_isValid) return;
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final appColors = AppColors.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: appColors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(appColors),
              _buildHeader(appColors),
              const SizedBox(height: 12),
              _buildWeightInput(appColors, isDarkMode),
              const SizedBox(height: 8),
              _buildComparison(appColors),
              const SizedBox(height: 8),
              _buildKeypad(isDarkMode),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(AppColors appColors) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: appColors.textDisabled,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(AppColors appColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
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
      decoration: BoxDecoration(
        color: appColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
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
              color: Colors.blue.shade600,
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
              color: Colors.orange.shade600,
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
              color: Colors.green.shade600,
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
              : Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      label!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
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

  Widget _buildWeightInput(AppColors appColors, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.teal.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.scale, color: Colors.teal, size: 18),
              const SizedBox(width: 8),
              const Text(
                'New Weight',
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _weightText.isEmpty ? '0' : _weightText,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  color: _weightText.isEmpty
                      ? appColors.textDisabled
                      : (isDarkMode ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'g',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        ],
      ),
    );
  }

  Widget _buildKeypad(bool isDarkMode) {
    final keys = [
      ['1', '2', '3', '⌫'],
      ['4', '5', '6', 'C'],
      ['7', '8', '9', '.'],
      ['0', 'Save'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: keys.map((row) {
          return Row(
            children: row.map((key) {
              final isSave = key == 'Save';
              final isWideZero = key == '0' && row.length == 2;
              return Expanded(
                flex: (isSave || isWideZero) ? 2 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _buildKeypadButton(key, isDarkMode),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeypadButton(String key, bool isDarkMode) {
    final isSave = key == 'Save';

    Color backgroundColor;
    Color textColor;

    if (isSave) {
      backgroundColor = _isValid ? Colors.teal : Colors.grey;
      textColor = Colors.white;
    } else if (key == 'C') {
      backgroundColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red;
    } else if (key == '⌫') {
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
        onTap: isSave ? _onSubmit : () => _onKeyPress(key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: key == '⌫'
              ? Icon(Icons.backspace_outlined, color: textColor, size: 22)
              : Text(
                  key,
                  style: TextStyle(
                    fontSize: isSave ? 16 : 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }
}
