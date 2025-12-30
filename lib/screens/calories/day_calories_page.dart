import 'package:cat_calories/blocs/calories/calories_cubit.dart';
import 'package:cat_calories/blocs/calories/calories_state.dart';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/ui/colors.dart';
import 'package:cat_calories/ui/widgets/calculator_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class DayCaloriesPage extends StatefulWidget {
  final DateTime startDate;

  const DayCaloriesPage(this.startDate);

  @override
  State<StatefulWidget> createState() => _DayCaloriesPageState(startDate);
}

class _DayCaloriesPageState extends State<DayCaloriesPage> {
  final DateTime startDate;

  bool _invertSorting = false;

  _DayCaloriesPageState(this.startDate);

  TextEditingController _calorieItemController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    context.read<CaloriesCubit>().fetch(_invertSorting, startDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calories ' + DateFormat('MMM d, y').format(startDate),
        ),
        actions: [
          IconButton(
            icon: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationX(_invertSorting ? math.pi : 0),
                child: Icon(Icons.sort)),
            onPressed: () {
              setState(() {
                _invertSorting = !_invertSorting;
              });
            },
          ),
        ],
      ),
      body: Container(
        child: BlocBuilder<CaloriesCubit, AbstractCaloriesState>(
          builder: (context, AbstractCaloriesState state) {
            if (state is CaloriesFetchInProgressState) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (state is CaloriesFetchSuccessState) {
              return ListView(
                children:
                    state.calorieItems.map((CalorieItemModel calorieItem) {
                  return ListTile(
                    title: Text('${calorieItem.value} kcal'),
                    subtitle: Text(
                      DateFormat('HH:mm').format(calorieItem.createdAt),
                    ),
                    onTap: () {
                      showModalBottomSheet<dynamic>(
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return Wrap(
                              children: <Widget>[
                                ListTile(
                                  title: Text('Remove'),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    context
                                        .read<CaloriesCubit>()
                                        .removeCalorieItem(
                                          calorieItem,
                                          _invertSorting,
                                          startDate,
                                        );

                                    // _removeCalorieItem(calorieItem, _calorieItems);
                                  },
                                ),
                              ],
                            );
                          });
                    },
                  );
                }).toList(),
              );
            }
            return Center(
              child: Text('Error'),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet<dynamic>(
            barrierColor: Colors.black.withOpacity(0.2),
            isScrollControlled: true,
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                  builder: (BuildContext context, StateSetter stateSetter) {
                return FractionallySizedBox(
                  child: Wrap(
                    children: <Widget>[
                      Builder(
                        builder: (context) => Form(
                          child: Column(
                            children: <Widget>[
                              Container(
                                color: Color(0xFFEEEEEE),
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    fillColor: SuccessColor,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 10.0, horizontal: 10.0),
                                    suffix: Text('kCal'),
                                    prefix: Text('+'),
                                  ),
                                  validator: (value) {
                                    // if (value.isEmpty) {
                                    //   return 'Please enter some value';
                                    // }
                                    return null;
                                  },
                                  maxLines: 1,
                                  controller: _calorieItemController,
                                ),
                              ),
                              CalculatorWidget(
                                controller: _calorieItemController,
                                onPressed: () {
                                  context
                                      .read<CaloriesCubit>()
                                      .createCalorieItem(
                                        double.parse(
                                            _calorieItemController.text),
                                        _invertSorting,
                                        startDate,
                                      );

                                  _calorieItemController.text = '';
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                );
              });
            },
          );
        },
      ),
    );
  }
}
