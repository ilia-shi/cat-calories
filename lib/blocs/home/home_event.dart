import 'package:cat_calories/features/products/domain/product_model.dart';
import 'package:cat_calories/features/products/domain/product_category_model.dart';
import 'package:cat_calories/features/profile/domain/profile_model.dart';
import 'package:cat_calories/features/waking_periods/domain/waking_period_model.dart';

import '../../features/calorie_tracking/domain/calorie_item_model.dart';

abstract class AbstractHomeEvent {}

class CalorieItemListFetchingInProgressEvent extends AbstractHomeEvent {}

class HomeFetchedEvent extends AbstractHomeEvent {}

/// Event to dismiss an error and optionally retry or restore previous state
class HomeErrorDismissedEvent extends AbstractHomeEvent {
  final bool retry;

  HomeErrorDismissedEvent({this.retry = false});
}

class CreatingCalorieItemEvent extends AbstractHomeEvent {
  String expression;
  List<CalorieItemModel> calorieItems;
  WakingPeriodModel wakingPeriod;
  final void Function(CalorieItemModel) callback;

  CreatingCalorieItemEvent(
    this.expression,
    this.wakingPeriod,
    this.calorieItems,
    this.callback,
  );
}

class CreatingCalorieItemWithNutritionEvent extends AbstractHomeEvent {
  final double calories;
  final WakingPeriodModel wakingPeriod;
  final List<CalorieItemModel> calorieItems;
  final double weightGrams;
  final double? proteinGrams;
  final double? fatGrams;
  final double? carbGrams;
  final String? description;
  final String? productId;
  final void Function(CalorieItemModel) callback;

  CreatingCalorieItemWithNutritionEvent({
    required this.calories,
    required this.wakingPeriod,
    required this.calorieItems,
    required this.weightGrams,
    this.proteinGrams,
    this.fatGrams,
    this.carbGrams,
    this.description,
    this.productId,
    required this.callback,
  });
}

class EatProductEvent extends AbstractHomeEvent {
  ProductModel product;
  double weightGrams;
  List<CalorieItemModel> calorieItems;
  WakingPeriodModel wakingPeriod;
  final void Function(CalorieItemModel) callback;

  EatProductEvent(
    this.product,
    this.weightGrams,
    this.wakingPeriod,
    this.calorieItems,
    this.callback,
  );
}

class EatEntirePackageEvent extends AbstractHomeEvent {
  final ProductModel product;
  final List<CalorieItemModel> calorieItems;
  final WakingPeriodModel wakingPeriod;
  final void Function(CalorieItemModel) callback;

  EatEntirePackageEvent({
    required this.product,
    required this.calorieItems,
    required this.wakingPeriod,
    required this.callback,
  });
}

class ChangeProfileEvent extends AbstractHomeEvent {
  final ProfileModel profile;
  final dynamic callback;

  ChangeProfileEvent(this.profile, this.callback);
}

class RemovingCalorieItemEvent extends AbstractHomeEvent {
  final CalorieItemModel calorieItem;
  final List<CalorieItemModel> calorieItems;
  final callback;

  RemovingCalorieItemEvent(this.calorieItem, this.calorieItems, this.callback);
}

class CalorieItemEatingEvent extends AbstractHomeEvent {
  final CalorieItemModel calorieItem;

  CalorieItemEatingEvent(this.calorieItem);
}

class CalorieItemListUpdatingEvent extends AbstractHomeEvent {
  final CalorieItemModel calorieItem;
  final List<CalorieItemModel> calorieItems;
  final callback;

  CalorieItemListUpdatingEvent(
      this.calorieItem, this.calorieItems, this.callback);
}

class CalorieItemListResortingEvent extends AbstractHomeEvent {
  CalorieItemListResortingEvent(this.items);

  final List<CalorieItemModel> items;
}

class ProfileCreatingEvent extends AbstractHomeEvent {
  ProfileModel profile;
  final callback;

  ProfileCreatingEvent(this.profile, this.callback);
}

class ProfileUpdatingEvent extends AbstractHomeEvent {
  ProfileModel profile;

  ProfileUpdatingEvent(this.profile);
}

class ProfileDeletingEvent extends AbstractHomeEvent {
  ProfileModel profile;

  ProfileDeletingEvent(this.profile);
}

class WakingPeriodCreatingEvent extends AbstractHomeEvent {
  final WakingPeriodModel wakingPeriod;

  WakingPeriodCreatingEvent(this.wakingPeriod);
}

class WakingPeriodEndingEvent extends AbstractHomeEvent {
  final WakingPeriodModel wakingPeriod;
  final double caloriesValue;

  WakingPeriodEndingEvent(this.wakingPeriod, this.caloriesValue);
}

class WakingPeriodDeletingEvent extends AbstractHomeEvent {
  final WakingPeriodModel wakingPeriod;

  WakingPeriodDeletingEvent(this.wakingPeriod);
}

class WakingPeriodUpdatingEvent extends AbstractHomeEvent {
  final WakingPeriodModel wakingPeriod;

  WakingPeriodUpdatingEvent(this.wakingPeriod);
}

class RemovingCaloriesByCreatedAtDayEvent extends AbstractHomeEvent {
  final DateTime date;
  final ProfileModel profile;

  RemovingCaloriesByCreatedAtDayEvent(this.date, this.profile);
}

class CaloriePreparedEvent extends AbstractHomeEvent {
  final String expression;

  CaloriePreparedEvent(this.expression);
}

// ============================================================================
// Product Events
// ============================================================================

class CreateProductEvent extends AbstractHomeEvent {
  final String title;
  final String? description;
  final String? barcode;
  final double? caloriesPer100g;
  final double? proteinsPer100g;
  final double? fatsPer100g;
  final double? carbsPer100g;
  final double? packageWeightGrams;
  final String? categoryId;

  CreateProductEvent({
    required this.title,
    this.description,
    this.barcode,
    this.caloriesPer100g,
    this.proteinsPer100g,
    this.fatsPer100g,
    this.carbsPer100g,
    this.packageWeightGrams,
    this.categoryId,
  });
}

class UpdateProductEvent extends AbstractHomeEvent {
  final ProductModel product;

  UpdateProductEvent(this.product);
}

class DeleteProductEvent extends AbstractHomeEvent {
  final ProductModel product;

  DeleteProductEvent(this.product);
}

class ProductsResortEvent extends AbstractHomeEvent {
  ProductsResortEvent(this.products);

  final List<ProductModel> products;
}

// ============================================================================
// Product Category Events
// ============================================================================

class CreateProductCategoryEvent extends AbstractHomeEvent {
  final String name;
  final String? iconName;
  final String? colorHex;

  CreateProductCategoryEvent({
    required this.name,
    this.iconName,
    this.colorHex,
  });
}

class UpdateProductCategoryEvent extends AbstractHomeEvent {
  final ProductCategoryModel category;

  UpdateProductCategoryEvent(this.category);
}

class DeleteProductCategoryEvent extends AbstractHomeEvent {
  final ProductCategoryModel category;

  DeleteProductCategoryEvent(this.category);
}

class ProductCategoriesResortEvent extends AbstractHomeEvent {
  final List<ProductCategoryModel> categories;

  ProductCategoriesResortEvent(this.categories);
}

/// Event to initialize default categories if none exist
class InitializeDefaultCategoriesEvent extends AbstractHomeEvent {}
