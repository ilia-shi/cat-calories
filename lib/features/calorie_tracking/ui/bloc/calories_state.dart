import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';

abstract class AbstractCaloriesState {}

class CaloriesFetchInProgressState extends AbstractCaloriesState {}

class CaloriesFetchSuccessState extends AbstractCaloriesState {
  final Iterable<CalorieRecord> calorieItems;

  CaloriesFetchSuccessState(this.calorieItems);
}
