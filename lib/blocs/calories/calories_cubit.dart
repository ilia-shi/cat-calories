import 'package:cat_calories/blocs/calories/calories_state.dart';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/models/profile_model.dart';
import 'package:cat_calories/repositories/calorie_item_repository.dart';
import 'package:cat_calories/repositories/waking_period_repository.dart';
import 'package:cat_calories/service/profile_resolver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class CaloriesCubit extends Cubit<AbstractCaloriesState> {
  final locator = GetIt.instance;

  late CalorieItemRepository calorieItemRepository =
      locator.get<CalorieItemRepository>();

  late WakingPeriodRepository wakingPeriodRepository =
      locator.get<WakingPeriodRepository>();

  ProfileResolver profileResolver = ProfileResolver();

  CaloriesCubit() : super(CaloriesFetchInProgressState());

  void fetch(bool invertSortOrder, DateTime dayStart) async {
    emit(CaloriesFetchInProgressState());

    fetchCalorieItems(invertSortOrder, dayStart);
  }

  void createCalorieItem(
      double value, bool invertSortOrder, DateTime dayStart) async {
    ProfileModel profile = await ProfileResolver().resolve();

    CalorieItemModel calorieItem = CalorieItemModel(
      id: null,
      value: value,
      description: null,
      sortOrder: 0,
      eatenAt: null,
      createdAt: dayStart,
      profileId: profile.id!,
      wakingPeriodId: null,
    );

    calorieItemRepository.insert(calorieItem);

    fetchCalorieItems(invertSortOrder, dayStart);
  }

  void removeCalorieItem(CalorieItemModel calorieItem, bool invertSortOrder,
      DateTime dateTime) async {
    calorieItemRepository.delete(calorieItem);

    fetchCalorieItems(invertSortOrder, dateTime);
  }

  void fetchCalorieItems(bool invertSortOrder, DateTime dayStart) async {
    final ProfileModel profile = await ProfileResolver().resolve();

    final calorieItems = await calorieItemRepository.fetchAllByProfileAndDay(
        profile,
        orderBy: 'created_at ' + (invertSortOrder ? 'ASC' : 'DESC'),
        limit: 50,
        dayStart: dayStart);

    emit(CaloriesFetchSuccessState(calorieItems));
  }
}
