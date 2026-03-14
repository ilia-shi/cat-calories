import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/waking_period_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'edit_waking_period_screen.dart';

class WakingPeriodsScreen extends StatefulWidget {
  WakingPeriodsScreen({Key? key}) : super(key: key);

  @override
  _WakingPeriodsScreenState createState() => _WakingPeriodsScreenState();
}

class _WakingPeriodsScreenState extends State<WakingPeriodsScreen> {
  void _removeWakingPeriod(WakingPeriodModel wakingPeriod) {
    BlocProvider.of<HomeBloc>(context)
        .add(WakingPeriodDeletingEvent(wakingPeriod));

    final snackBar = SnackBar(content: Text('Waking period removed'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Waking Periods')),
      body: BlocBuilder<HomeBloc, AbstractHomeState>(
        builder: (context, state) {
          if (state is HomeFetchingInProgress) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is HomeFetched) {
            final List<WakingPeriodModel> wakingPeriods = state.wakingPeriods;

            return ListView.builder(
              itemCount: wakingPeriods.length,
              itemBuilder: (BuildContext context, int index) {
                final WakingPeriodModel wakingPeriod = wakingPeriods[index];

                if (state.currentWakingPeriod != null &&
                    wakingPeriod.id == state.currentWakingPeriod!.id) {
                  return ListTile(
                    contentPadding: EdgeInsets.fromLTRB(25, 10, 25, 10),
                    tileColor: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.1),
                    title: Text('Current waking period'),
                    subtitle: Text(
                        'From ${DateFormat('MMM d, HH:mm').format(wakingPeriod.createdAt)}'),
                  );
                }

                return ListTile(
                  contentPadding: EdgeInsets.fromLTRB(25, 10, 25, 10),
                  key: Key(index.toString()),
                  title: Text(
                      '${wakingPeriod.caloriesValue.toStringAsFixed(2)} kCal'),
                  subtitle: Text(
                      '${DateFormat('MMM d, HH:mm').format(wakingPeriod.startedAt)} - ${DateFormat('MMM d, HH:mm').format(wakingPeriod.endedAt!)}'),
                  onTap: () {
                    showModalBottomSheet<dynamic>(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return Wrap(
                            children: <Widget>[
                              ListTile(
                                title: Text('Edit'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            EditWakingPeriodScreen(
                                                wakingPeriod)),
                                  );
                                },
                              ),
                              ListTile(
                                title: Text('Remove'),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Remove waking period'),
                                        content: Text('Continue?'),
                                        actions: [
                                          TextButton(
                                            child: Text("Cancel"),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                          TextButton(
                                            child: Text("Ok"),
                                            onPressed: () {
                                              _removeWakingPeriod(wakingPeriod);
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
                        });
                  },
                );
              },
            );
          }

          return Center(
            child: Text('Error'),
          );
        },
      ),
    );
  }
}
