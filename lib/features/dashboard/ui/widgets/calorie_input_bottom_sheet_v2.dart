import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_event.dart';
import 'package:cat_calories/common/widgets/calculator/calorie_calculator_sheet.dart';
import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Logs what the shared [CalorieCalculatorSheet] produces into the current
/// waking period through [HomeBloc].
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
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return CalorieCalculatorSheet(
      isSubmitting: _isSubmitting,
      onQuickAddChanged: (expression) =>
          context.read<HomeBloc>().add(CaloriePreparedEvent(expression)),
      onSubmit: _submit,
    );
  }

  void _submit(CalorieCalculatorResult result) {
    setState(() {
      _isSubmitting = true;
    });

    final bloc = context.read<HomeBloc>();
    final expression = result.expression;

    if (expression != null) {
      bloc.add(
        CreatingCalorieItemEvent(
          expression,
          widget.wakingPeriod,
          widget.calorieItems,
          _onCalorieItemCreated,
        ),
      );
      return;
    }

    bloc.add(
      CreatingCalorieItemWithNutritionEvent(
        calories: result.calories,
        wakingPeriod: widget.wakingPeriod,
        calorieItems: widget.calorieItems,
        weightGrams: result.weightGrams!,
        proteinGrams: result.proteinGrams,
        fatGrams: result.fatGrams,
        carbGrams: result.carbGrams,
        callback: _onCalorieItemCreated,
      ),
    );
  }

  void _onCalorieItemCreated(CalorieRecord calorieItem) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    Navigator.of(context).pop();

    String message = '${calorieItem.value.toStringAsFixed(0)} kcal added';
    if (calorieItem.weightGrams != null) {
      message = '${calorieItem.weightGrams!.toStringAsFixed(0)}g • $message';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
