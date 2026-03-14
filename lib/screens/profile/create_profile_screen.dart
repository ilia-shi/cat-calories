import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateProfileScreen extends StatefulWidget {
  CreateProfileScreen();

  @override
  CreateProfileScreenState createState() => CreateProfileScreenState();
}

class CreateProfileScreenState extends State<CreateProfileScreen> {
  TextEditingController _nameController = new TextEditingController();
  TextEditingController _wakingTimeHours = new TextEditingController();
  TextEditingController _caloriesLimitGoal = new TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wakingTimeHours.dispose();
    _caloriesLimitGoal.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create profile', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
            ),
            onPressed: () {
              if (!_formKey.currentState!.validate()) {
                return;
              }

              final ProfileModel profile = ProfileModel(
                id: null,
                name: _nameController.text,
                wakingTimeSeconds: int.parse(_wakingTimeHours.text) * 60 * 60,
                caloriesLimitGoal: double.parse(_caloriesLimitGoal.text),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              BlocProvider.of<HomeBloc>(context).add(ProfileCreatingEvent(profile, () {}));

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
                    decoration: InputDecoration(
                      labelText: 'Name',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    controller: _nameController,
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter profile name';
                      }

                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Waking time (hours)',
                      suffix: Text('hours'),
                    ),
                    controller: _wakingTimeHours,
                    keyboardType: TextInputType.number,
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please waking time';
                      }

                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Calories limit goal',
                      suffix: Text('kCal'),
                    ),
                    controller: _caloriesLimitGoal,
                    keyboardType: TextInputType.number,
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter calories limit goal';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
