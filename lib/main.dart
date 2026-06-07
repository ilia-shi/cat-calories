import 'package:cat_calories/blocs/calories/calories_cubit.dart';
import 'package:cat_calories/blocs/theme/theme_cubit.dart';
import 'package:cat_calories/blocs/theme/theme_state.dart';
import 'package:cat_calories/database/app_database.dart';
import 'package:cat_calories/features/calorie_tracking/data/sqlite/seeds/calorie_item_seeds.dart';
import 'package:cat_calories/features/profile/data/sqlite/profile_seeds.dart';
import 'package:cat_calories/common/locator.dart';
import 'package:cat_calories/locator.dart';
import 'package:cat_calories/service/sync_service.dart';
import 'package:cat_calories/service/embedded_server_service.dart';
import 'package:cat_calories/ui/theme.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/screens/home/home_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> _seedIfNeeded() async {
  if (!kDebugMode) return;

  await AppDatabase.instance.getDatabase();

  if (!AppDatabase.instance.isNewDatabase) return;

  final profile = await ProfileSeeds.seed();
  await CalorieItemSeedExecutor.seedIfNeeded(profileId: profile.id!);
}

void main() {
  runZonedGuarded(() {
    print('=== CAT CALORIES STARTING ===');
    WidgetsFlutterBinding.ensureInitialized();
    print('[BOOT] WidgetsFlutterBinding initialized');

    FlutterError.onError = (FlutterErrorDetails details) {
      print('=== FLUTTER ERROR ===');
      print(details.exceptionAsString());
      print(details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      print('=== PLATFORM ERROR ===');
      print(error);
      print(stack);
      return true;
    };

    print('[BOOT] Registering services...');
    registerServices();
    print('[BOOT] Services registered');

    _seedIfNeeded();

    locator.get<SyncService>().init();
    print('[BOOT] SyncService.init() called (async)');
    print('[BOOT] Calling runApp...');
    runApp(App());
    print('[BOOT] runApp completed');
  }, (error, stack) {
    print('=== ZONE ERROR ===');
    print(error);
    print(stack);
  });
}

class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    print('[BOOT] _AppState.initState()');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      locator.get<EmbeddedServerService>().screenEnergy.restoreBrightness();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            return HomeBloc();
          },
        ),
        BlocProvider(
          create: (context) {
            return CaloriesCubit();
          },
        ),
        BlocProvider(
          create: (context) {
            return ThemeCubit();
          },
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          print('[BOOT] BlocBuilder builder called, themeMode=${themeState.themeMode}');
          return Listener(
            onPointerDown: (_) => locator.get<EmbeddedServerService>().screenEnergy.onUserActivity(),
            child: MaterialApp(
              theme: CustomTheme.lightTheme,
              darkTheme: CustomTheme.darkTheme,
              themeMode: themeState.flutterThemeMode,
              debugShowCheckedModeBanner: false,
              title: 'Cat Calories',
              home: HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}