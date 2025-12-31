import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/screens/edit_calorie_item_screen.dart';
import 'package:cat_calories/ui/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class FoodIntakesView extends StatefulWidget {
  FoodIntakesView({Key? key}) : super(key: key);

  @override
  _FoodIntakesViewState createState() => _FoodIntakesViewState();
}

class _FoodIntakesViewState extends State<FoodIntakesView> {
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        if (state is HomeFetchingInProgress) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (state is HomeFetched) {
          final _calorieItems = state.periodCalorieItems;

          if (_calorieItems.length == 0) {
            return Center(
              child: Text('No calorie items'),
            );
          }
        }

        return Center(
          child: Text('Error'),
        );
      },
    );
  }
}
