// lib/screens/home/widgets/home_floating_action_button.dart

import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'calorie_input_bottom_sheet.dart';

class HomeFloatingActionButton extends StatelessWidget {
  const HomeFloatingActionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        final isEnabled = state is HomeFetched && state.currentWakingPeriod != null;

        return FloatingActionButton(
          onPressed: isEnabled
              ? () => _showCalorieInputSheet(context, state as HomeFetched)
              : null,
          backgroundColor: isEnabled
              ? Theme.of(context).floatingActionButtonTheme.backgroundColor
              : Theme.of(context).disabledColor,
          child: const Icon(Icons.add),
        );
      },
    );
  }

  void _showCalorieInputSheet(BuildContext context, HomeFetched state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return BlocProvider.value(
          value: context.read<HomeBloc>(),
          child: CalorieInputBottomSheet(
            wakingPeriod: state.currentWakingPeriod!,
            calorieItems: state.periodCalorieItems,
          ),
        );
      },
    );
  }
}