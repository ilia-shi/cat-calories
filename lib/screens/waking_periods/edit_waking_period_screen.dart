import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/waking_period_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

const DATE_TIME_FORMAT = 'MMM d, y HH:mm';

class EditWakingPeriodScreen extends StatefulWidget {
  WakingPeriodModel wakingPeriod;

  EditWakingPeriodScreen(this.wakingPeriod);

  @override
  EditWakingPeriodScreenState createState() => EditWakingPeriodScreenState(this.wakingPeriod);
}

class EditWakingPeriodScreenState extends State<EditWakingPeriodScreen> {
  WakingPeriodModel wakingPeriod;

  TextEditingController _caloriesController = TextEditingController();
  TextEditingController _expectedWakingHours = TextEditingController();
  TextEditingController _caloriesLimitGoal = TextEditingController();
  TextEditingController _startedAt = TextEditingController();

  EditWakingPeriodScreenState(this.wakingPeriod);

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _caloriesController.text = wakingPeriod.caloriesValue.toString();
    _expectedWakingHours.text = (wakingPeriod.getExpectedWakingDuration().inHours).toString();
    _caloriesLimitGoal.text = wakingPeriod.caloriesLimitGoal.toString();
    _startedAt.text = DateFormat(DATE_TIME_FORMAT).format(wakingPeriod.startedAt);
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _expectedWakingHours.dispose();
    _caloriesLimitGoal.dispose();
    _startedAt.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit waking period', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
            ),
            onPressed: () {

              if (!_formKey.currentState!.validate()) {
                return;
              }

              wakingPeriod.caloriesValue = double.parse(_caloriesController.text);
              wakingPeriod.setExpectedWakingDuration(Duration(hours: int.parse(_expectedWakingHours.text)));
              wakingPeriod.caloriesLimitGoal = double.parse(_caloriesLimitGoal.text);
              wakingPeriod.startedAt = DateFormat(DATE_TIME_FORMAT).parse(_startedAt.text);

              BlocProvider.of<HomeBloc>(context).add(WakingPeriodUpdatingEvent(wakingPeriod));

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: BlocBuilder<HomeBloc, AbstractHomeState>(builder: (BuildContext context, state) {
          return Form(
              key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Wrap(
              children: <Widget>[
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Calories',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  controller: _caloriesController,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter calories';
                    }

                    return null;
                  },
                ),


                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Expected waking hours',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  controller: _expectedWakingHours,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter hours';
                    }

                    return null;
                  },
                ),

                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Calories limit goal',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  controller: _caloriesLimitGoal,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter calories limit goal';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    labelText: 'Started at',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  controller: _startedAt,
                  validator: (String? value) {
                    try {
                      DateFormat(DATE_TIME_FORMAT).parse(_startedAt.text);

                      return null;
                    } catch (e) {
                      return 'Please enter valid date (example: Jun 12, 2012 07:16)';
                    }
                  },
                ),
              ],
            ),
          ),);
        }),
      ),
    );
  }
}
