import 'package:cat_calories/blocs/calories/calories_cubit.dart';
import 'package:cat_calories/blocs/theme/theme_cubit.dart';
import 'package:cat_calories/blocs/theme/theme_state.dart';
import 'package:cat_calories/locator.dart';
import 'package:cat_calories/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/screens/home/home_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerServices();
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HomeBloc(),
        ),
        BlocProvider(
          create: (context) => CaloriesCubit(),
        ),
        BlocProvider(
          create: (context) => ThemeCubit(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            theme: CustomTheme.lightTheme,
            darkTheme: CustomTheme.darkTheme,
            themeMode: themeState.flutterThemeMode,
            debugShowCheckedModeBanner: false,
            title: 'Cat Calories',
            home: HomeScreen(),
          );
        },
      ),
    );
  }
}