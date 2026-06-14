import 'dart:ui' show ImageFilter;

import 'package:cat_calories/app/state/home_bloc.dart';
import 'package:cat_calories/app/state/home_state.dart';
import 'package:cat_calories/common/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'calorie_input_bottom_sheet_v2.dart';

class HomeFloatingActionButton extends StatelessWidget {
  const HomeFloatingActionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        final isEnabled =
            state is HomeFetched && state.currentWakingPeriod != null;

        final theme = Theme.of(context);
        final baseColor = isEnabled
            ? theme.floatingActionButtonTheme.backgroundColor ??
                theme.colorScheme.primary
            : theme.disabledColor;

        return ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: CustomTheme.surfaceBlurSigma,
              sigmaY: CustomTheme.surfaceBlurSigma,
            ),
            child: FloatingActionButton(
              onPressed: isEnabled
                  ? () => _showCalorieInputSheet(context, state)
                  : null,
              backgroundColor:
                  baseColor.withValues(alpha: CustomTheme.surfaceOpacity),
              elevation: 0,
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  void _showCalorieInputSheet(BuildContext context, HomeFetched state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return BlocProvider.value(
          value: context.read<HomeBloc>(),
          child: CalorieInputBottomSheetV2(
            wakingPeriod: state.currentWakingPeriod!,
            calorieItems: state.periodCalorieItems,
          ),
        );
      },
    );
  }
}
