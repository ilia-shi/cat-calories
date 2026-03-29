import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/products/domain/product_category.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:cat_calories_core/features/waking_periods/domain/waking_period.dart';

import 'package:cat_calories_core/features/calorie_tracking/domain/calorie_record.dart';

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
  List<CalorieRecord> calorieItems;
  WakingPeriod wakingPeriod;
  final void Function(CalorieRecord) callback;

  CreatingCalorieItemEvent(
    this.expression,
    this.wakingPeriod,
    this.calorieItems,
    this.callback,
  );
}

class CreatingCalorieItemWithNutritionEvent extends AbstractHomeEvent {
  final double calories;
  final WakingPeriod wakingPeriod;
  final List<CalorieRecord> calorieItems;
  final double weightGrams;
  final double? proteinGrams;
  final double? fatGrams;
  final double? carbGrams;
  final String? description;
  final String? productId;
  final void Function(CalorieRecord) callback;

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
  Product product;
  double weightGrams;
  List<CalorieRecord> calorieItems;
  WakingPeriod wakingPeriod;
  final void Function(CalorieRecord) callback;

  EatProductEvent(
    this.product,
    this.weightGrams,
    this.wakingPeriod,
    this.calorieItems,
    this.callback,
  );
}

class EatEntirePackageEvent extends AbstractHomeEvent {
  final Product product;
  final List<CalorieRecord> calorieItems;
  final WakingPeriod wakingPeriod;
  final void Function(CalorieRecord) callback;

  EatEntirePackageEvent({
    required this.product,
    required this.calorieItems,
    required this.wakingPeriod,
    required this.callback,
  });
}

class ChangeProfileEvent extends AbstractHomeEvent {
  final Profile profile;
  final dynamic callback;

  ChangeProfileEvent(this.profile, this.callback);
}

class RemovingCalorieItemEvent extends AbstractHomeEvent {
  final CalorieRecord calorieItem;
  final List<CalorieRecord> calorieItems;
  final callback;

  RemovingCalorieItemEvent(this.calorieItem, this.calorieItems, this.callback);
}

class CalorieItemEatingEvent extends AbstractHomeEvent {
  final CalorieRecord calorieItem;

  CalorieItemEatingEvent(this.calorieItem);
}

class CalorieItemListUpdatingEvent extends AbstractHomeEvent {
  final CalorieRecord calorieItem;
  final List<CalorieRecord> calorieItems;
  final callback;

  CalorieItemListUpdatingEvent(
      this.calorieItem, this.calorieItems, this.callback);
}

class CalorieItemListResortingEvent extends AbstractHomeEvent {
  CalorieItemListResortingEvent(this.items);

  final List<CalorieRecord> items;
}

class ProfileCreatingEvent extends AbstractHomeEvent {
  Profile profile;
  final callback;

  ProfileCreatingEvent(this.profile, this.callback);
}

class ProfileUpdatingEvent extends AbstractHomeEvent {
  Profile profile;

  ProfileUpdatingEvent(this.profile);
}

class ProfileDeletingEvent extends AbstractHomeEvent {
  Profile profile;

  ProfileDeletingEvent(this.profile);
}

class WakingPeriodCreatingEvent extends AbstractHomeEvent {
  final WakingPeriod wakingPeriod;

  WakingPeriodCreatingEvent(this.wakingPeriod);
}

class WakingPeriodEndingEvent extends AbstractHomeEvent {
  final WakingPeriod wakingPeriod;
  final double caloriesValue;

  WakingPeriodEndingEvent(this.wakingPeriod, this.caloriesValue);
}

class WakingPeriodDeletingEvent extends AbstractHomeEvent {
  final WakingPeriod wakingPeriod;

  WakingPeriodDeletingEvent(this.wakingPeriod);
}

class WakingPeriodUpdatingEvent extends AbstractHomeEvent {
  final WakingPeriod wakingPeriod;

  WakingPeriodUpdatingEvent(this.wakingPeriod);
}

class RemovingCaloriesByCreatedAtDayEvent extends AbstractHomeEvent {
  final DateTime date;
  final Profile profile;

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
  final Product product;

  UpdateProductEvent(this.product);
}

class DeleteProductEvent extends AbstractHomeEvent {
  final Product product;

  DeleteProductEvent(this.product);
}

class ProductsResortEvent extends AbstractHomeEvent {
  ProductsResortEvent(this.products);

  final List<Product> products;
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
  final ProductCategory category;

  UpdateProductCategoryEvent(this.category);
}

class DeleteProductCategoryEvent extends AbstractHomeEvent {
  final ProductCategory category;

  DeleteProductCategoryEvent(this.category);
}

class ProductCategoriesResortEvent extends AbstractHomeEvent {
  final List<ProductCategory> categories;

  ProductCategoriesResortEvent(this.categories);
}

/// Event to initialize default categories if none exist
class InitializeDefaultCategoriesEvent extends AbstractHomeEvent {}
