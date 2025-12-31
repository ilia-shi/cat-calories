import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/models/waking_period_model.dart';
import 'package:cat_calories/ui/colors.dart';
import 'package:cat_calories/ui/widgets/calculator_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalorieInputBottomSheet extends StatefulWidget {
  final WakingPeriodModel wakingPeriod;
  final List<CalorieItemModel> calorieItems;

  const CalorieInputBottomSheet({
    Key? key,
    required this.wakingPeriod,
    required this.calorieItems,
  }) : super(key: key);

  @override
  State<CalorieInputBottomSheet> createState() => _CalorieInputBottomSheetState();
}

class _CalorieInputBottomSheetState extends State<CalorieInputBottomSheet> {
  late final TextEditingController _calorieController;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _calorieController = TextEditingController();
    _calorieController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _calorieController.removeListener(_onInputChanged);
    _calorieController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    // Update the prepared calories in the bloc for real-time display
    context.read<HomeBloc>().add(CaloriePreparedEvent(_calorieController.text));
  }

  void _submitCalories() {
    final expression = _calorieController.text.trim();

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

  void _onCalorieItemCreated(CalorieItemModel calorieItem) {
    _calorieController.clear();

    setState(() {
      _isSubmitting = false;
    });

    Navigator.of(context).pop();

    _showSnackBar('${calorieItem.value.toStringAsFixed(0)} kcal added');
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(context),
            _buildInputField(context, isDarkMode),
            _buildCalculator(context),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Add Calories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: _formKey,
        child: TextFormField(
          controller: _calorieController,
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
      ),
    );
  }

  Widget _buildCalculator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: CalculatorWidget(
        controller: _calorieController,
        onPressed: _submitCalories,
      ),
    );
  }
}