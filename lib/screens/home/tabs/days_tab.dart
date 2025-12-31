import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/day_result.dart';
import 'package:cat_calories/screens/calories/day_calories_page.dart';
import 'package:cat_calories/ui/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DaysView extends StatefulWidget {
  DaysView({Key? key}) : super(key: key);

  @override
  _DaysViewState createState() => _DaysViewState();
}

class _DaysViewState extends State<DaysView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        if (state is HomeFetchingInProgress) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is HomeFetched) {
          final List<DayResultModel> dayResultItems = state.days30;

          return ListView.builder(
            itemCount: dayResultItems.length,
            itemBuilder: (BuildContext context, int index) {
              final DayResultModel dayItem = dayResultItems[index];

              return ListTile(
                leading: Icon(Icons.calendar_today_outlined),
                contentPadding: EdgeInsets.fromLTRB(25, 10, 25, 10),
                key: Key(index.toString()),
                title: Text(dayItem.valueSum.toStringAsFixed(2) + ' kcal'),
                trailing: Padding(
                    padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child: Column(
                      children: [
                        Text(
                          dayItem.negativeValueSum == 0
                              ? '-0.00'
                              : dayItem.negativeValueSum.toStringAsFixed(2),
                          style: TextStyle(fontSize: 12, color: SuccessColor),
                        ),
                        Text(
                          '+' + dayItem.positiveValueSum.toStringAsFixed(2),
                          style: TextStyle(fontSize: 12, color: DangerColor),
                        ),
                      ],
                    )),
                subtitle:
                    Text((DateFormat('MMM d, y').format(dayItem.createdAtDay))),
                onTap: () {
                  showModalBottomSheet<dynamic>(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return Wrap(
                        children: <Widget>[
                          ListTile(
                            title: Text('Show calorie items'),
                            onTap: () {
                              Navigator.of(context).pop();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DayCaloriesPage(
                                        dayItem.createdAtDay)),
                              );
                            },
                          ),
                          ListTile(
                            title: Text('Remove day calories'),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Remove day calories'),
                                    content: Text('Continue?'),
                                    actions: [
                                      MaterialButton(
                                        child: Text("Cancel"),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      MaterialButton(
                                        child: Text('Ok'),
                                        onPressed: () {
                                          BlocProvider.of<HomeBloc>(context).add(
                                              RemovingCaloriesByCreatedAtDayEvent(
                                                  dayItem.createdAtDay,
                                                  state.activeProfile));

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content:
                                                      Text('Day removed')));

                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        }

        return Center(
          child: Text('Error'),
        );
      },
    );
  }
}
