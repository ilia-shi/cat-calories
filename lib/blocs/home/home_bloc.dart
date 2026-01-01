import 'package:cat_calories/models/day_result.dart';
import 'package:cat_calories/models/product_model.dart';
import 'package:cat_calories/models/profile_model.dart';
import 'package:cat_calories/models/waking_period_model.dart';
import 'package:cat_calories/repositories/product_repository.dart';
import 'package:cat_calories/repositories/profile_repository.dart';
import 'package:cat_calories/repositories/waking_period_repository.dart';
import 'package:cat_calories/service/profile_resolver.dart';
import 'package:cat_calories/utils/expression_executor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/repositories/calorie_item_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_event.dart';
import 'package:cat_calories/models/equalization_settings_model.dart';
import 'package:cat_calories/service/calorie_recommendation_service.dart';

class HomeBloc extends Bloc<AbstractHomeEvent, AbstractHomeState> {
  final locator = GetIt.instance;

  // FIXED: Removed cached nowDateTime - now using DateTime.now() directly
  // to ensure we always get fresh data for the current day

  late ProductRepository productRepository = locator.get<ProductRepository>();
  late CalorieItemRepository calorieItemRepository =
  locator.get<CalorieItemRepository>();
  late ProfileRepository profileRepository = locator.get<ProfileRepository>();
  late WakingPeriodRepository wakingPeriodRepository =
  locator.get<WakingPeriodRepository>();

  ProfileModel? _activeProfile;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  double _preparedCaloriesValue = 0;

  HomeBloc() : super(HomeFetchingInProgress()) {
    // Register all event handlers
    on<CalorieItemListFetchingInProgressEvent>(_onCalorieItemListFetching);
    on<CreatingCalorieItemEvent>(_onCreatingCalorieItem);
    on<RemovingCalorieItemEvent>(_onRemovingCalorieItem);
    on<CalorieItemListResortingEvent>(_onCalorieItemListResorting);
    on<CalorieItemListUpdatingEvent>(_onCalorieItemListUpdating);
    on<ProfileCreatingEvent>(_onProfileCreating);
    on<ProfileUpdatingEvent>(_onProfileUpdating);
    on<ChangeProfileEvent>(_onChangeProfile);
    on<WakingPeriodCreatingEvent>(_onWakingPeriodCreating);
    on<WakingPeriodEndingEvent>(_onWakingPeriodEnding);
    on<WakingPeriodDeletingEvent>(_onWakingPeriodDeleting);
    on<WakingPeriodUpdatingEvent>(_onWakingPeriodUpdating);
    on<RemovingCaloriesByCreatedAtDayEvent>(_onRemovingCaloriesByCreatedAtDay);
    on<CalorieItemEatingEvent>(_onCalorieItemEating);
    on<ProfileDeletingEvent>(_onProfileDeleting);
    on<CaloriePreparedEvent>(_onCaloriePrepared);
    on<CreateProductEvent>(_onCreateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<EatProductEvent>(_onEatProduct);
    on<ProductsResortEvent>(_onProductsResort);
  }

  _saveActiveProfile(ProfileModel profile) async {
    SharedPreferences prefs = await _prefs;
    prefs.setInt(ProfileResolver.activeProfileKey, profile.id!);
  }

  Future<void> _ensureActiveProfile() async {
    if (_activeProfile == null) {
      _activeProfile = await ProfileResolver().resolve();
    }
  }

  Future<void> _onCalorieItemListFetching(
      CalorieItemListFetchingInProgressEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await _emitHomeData(emit);
  }

  Future<void> _onCreatingCalorieItem(
      CreatingCalorieItemEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();

    final CalorieItemModel calorieItem = CalorieItemModel(
      id: null,
      value: _preparedCaloriesValue,
      sortOrder: 0,
      eatenAt: DateTime.now(),
      createdAt: DateTime.now(),
      description: null,
      profileId: _activeProfile!.id!,
      wakingPeriodId: event.wakingPeriod.id!,
    );

    await calorieItemRepository.offsetSortOrder();
    await calorieItemRepository.insert(calorieItem);
    _preparedCaloriesValue = 0;

    event.callback(calorieItem);

    await _emitHomeData(emit);
  }

  Future<void> _onRemovingCalorieItem(
      RemovingCalorieItemEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await calorieItemRepository.delete(event.calorieItem);
    event.callback();
    await _emitHomeData(emit);
  }

  Future<void> _onCalorieItemListResorting(
      CalorieItemListResortingEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await calorieItemRepository.resort(event.items);
    await _emitHomeData(emit);
  }

  Future<void> _onCalorieItemListUpdating(
      CalorieItemListUpdatingEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await calorieItemRepository.update(event.calorieItem);
    await _emitHomeData(emit);
  }

  Future<void> _onProfileCreating(
      ProfileCreatingEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await profileRepository.insert(event.profile);
    await _emitHomeData(emit);
  }

  Future<void> _onProfileUpdating(
      ProfileUpdatingEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await profileRepository.update(event.profile);
    await _emitHomeData(emit);
  }

  Future<void> _onChangeProfile(
      ChangeProfileEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    _activeProfile = event.profile;
    _saveActiveProfile(event.profile);
    await _emitHomeData(emit);
  }

  Future<void> _onWakingPeriodCreating(
      WakingPeriodCreatingEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await wakingPeriodRepository.insert(event.wakingPeriod);
    await _emitHomeData(emit);
  }

  Future<void> _onWakingPeriodEnding(
      WakingPeriodEndingEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();

    final WakingPeriodModel wakingPeriod = event.wakingPeriod;
    wakingPeriod.updatedAt = DateTime.now();
    wakingPeriod.endedAt = DateTime.now();
    wakingPeriod.caloriesValue = event.caloriesValue;

    await wakingPeriodRepository.update(event.wakingPeriod);
    await _emitHomeData(emit);
  }

  Future<void> _onWakingPeriodDeleting(
      WakingPeriodDeletingEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await wakingPeriodRepository.delete(event.wakingPeriod);
    await _emitHomeData(emit);
  }

  Future<void> _onWakingPeriodUpdating(
      WakingPeriodUpdatingEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await wakingPeriodRepository.update(event.wakingPeriod);
    await _emitHomeData(emit);
  }

  Future<void> _onRemovingCaloriesByCreatedAtDay(
      RemovingCaloriesByCreatedAtDayEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await calorieItemRepository.deleteByCreatedAtDay(event.date, event.profile);
    await _emitHomeData(emit);
  }

  Future<void> _onCalorieItemEating(
      CalorieItemEatingEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();

    final CalorieItemModel calorieItem = event.calorieItem;
    calorieItem.eatenAt = calorieItem.isEaten() ? null : DateTime.now();

    await calorieItemRepository.update(calorieItem);
    await _emitHomeData(emit);
  }

  Future<void> _onProfileDeleting(
      ProfileDeletingEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();

    final List<ProfileModel> profiles = await profileRepository.fetchAll();

    if (profiles.length > 1) {
      await profileRepository.delete(event.profile);
    }

    _activeProfile = profiles.first;
    await _emitHomeData(emit);
  }

  Future<void> _onCaloriePrepared(
      CaloriePreparedEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    _preparedCaloriesValue = ExpressionExecutor.execute(event.expression);
    await _emitHomeData(emit);
  }

  Future<void> _onCreateProduct(
      CreateProductEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();

    final product = ProductModel(
      id: null,
      title: event.title,
      description: event.description,
      usesCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      profileId: _activeProfile!.id!,
      barcode: event.barcode,
      calorieContent: event.calorieContent,
      proteins: event.proteins,
      fats: event.fats,
      carbohydrates: event.carbohydrates,
      sortOrder: 0,
    );

    await productRepository.insert(product);
    await _emitHomeData(emit);
  }

  Future<void> _onDeleteProduct(
      DeleteProductEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await productRepository.delete(event.product);
    await _emitHomeData(emit);
  }

  Future<void> _onUpdateProduct(
      UpdateProductEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await productRepository.update(event.product);
    await _emitHomeData(emit);
  }

  Future<void> _onEatProduct(
      EatProductEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();

    final CalorieItemModel calorieItem = CalorieItemModel(
      id: null,
      value: (event.product.calorieContent! / 100) *
          ExpressionExecutor.execute(event.expression),
      sortOrder: 0,
      eatenAt: DateTime.now(),
      createdAt: DateTime.now(),
      description: event.product.title,
      profileId: _activeProfile!.id!,
      wakingPeriodId: event.wakingPeriod.id!,
    );

    event.product.usesCount = event.product.usesCount + 1;

    await calorieItemRepository.offsetSortOrder();
    await calorieItemRepository.insert(calorieItem);
    await productRepository.update(event.product);

    event.callback(calorieItem);
    await _emitHomeData(emit);
  }

  Future<void> _onProductsResort(
      ProductsResortEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    await productRepository.resort(event.products);
    await _emitHomeData(emit);
  }

  EqualizationSettingsModel _equalizationSettings = EqualizationSettingsModel();

  /// Fetch calorie items for the rolling window (last 48 hours).
  /// This covers any 24-hour window the user might need, plus buffer.
  Future<List<CalorieItemModel>> _fetchRollingWindowItems() async {
    final now = DateTime.now();
    final List<CalorieItemModel> allItems = [];

    // Fetch today's items
    final todayItems = await calorieItemRepository.fetchByCreatedAtDay(now);
    allItems.addAll(todayItems);

    // Fetch yesterday's items
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayItems = await calorieItemRepository.fetchByCreatedAtDay(yesterday);
    allItems.addAll(yesterdayItems);

    // Fetch day before yesterday (to ensure full 48h coverage for edge cases)
    final dayBeforeYesterday = now.subtract(const Duration(days: 2));
    final dayBeforeItems = await calorieItemRepository.fetchByCreatedAtDay(dayBeforeYesterday);
    allItems.addAll(dayBeforeItems);

    // Remove duplicates by ID (in case of overlap)
    final seen = <int>{};
    final uniqueItems = <CalorieItemModel>[];
    for (final item in allItems) {
      if (item.id != null && !seen.contains(item.id)) {
        seen.add(item.id!);
        uniqueItems.add(item);
      } else if (item.id == null) {
        uniqueItems.add(item);
      }
    }

    return uniqueItems;
  }

  Future<void> _emitHomeData(Emitter<AbstractHomeState> emit) async {
    final ProfileModel activeProfile = _activeProfile!;

    // FIXED: Always use fresh DateTime.now() to ensure we get data for the current day
    final DateTime nowDateTime = DateTime.now();

    // Calculate recommendation
    final recommendationService = CalorieRecommendationService(
      EqualizationSettingsModel(
        baseCalorieGoal: activeProfile.caloriesLimitGoal,
      ),
    );

    // FIXED: Using fresh nowDateTime to fetch today's items
    List<CalorieItemModel> todayCalorieItems =
    await calorieItemRepository.fetchByCreatedAtDay(nowDateTime);

    // Fetch rolling window items (last 48 hours) for the new rolling tracker
    List<CalorieItemModel> rollingWindowCalorieItems =
    await _fetchRollingWindowItems();

    DateTime? lastMealTime;
    if (todayCalorieItems.isNotEmpty) {
      final sortedItems = todayCalorieItems
          .where((item) => item.eatenAt != null)
          .toList()
        ..sort((a, b) => b.eatenAt!.compareTo(a.eatenAt!));
      if (sortedItems.isNotEmpty) {
        lastMealTime = sortedItems.first.eatenAt;
      }
    }

    // Also check rolling window for last meal time (might be from yesterday)
    if (lastMealTime == null && rollingWindowCalorieItems.isNotEmpty) {
      final sortedItems = rollingWindowCalorieItems
          .where((item) => item.eatenAt != null)
          .toList()
        ..sort((a, b) => b.eatenAt!.compareTo(a.eatenAt!));
      if (sortedItems.isNotEmpty) {
        lastMealTime = sortedItems.first.eatenAt;
      }
    }

    final List<DayResultModel> _dayResultsList30days =
    await calorieItemRepository.fetchDaysByProfile(activeProfile, 30);

    final recommendation = recommendationService.calculate(
      historicalDays: _dayResultsList30days,
      consumedToday: todayCalorieItems.fold<double>(
        0,
            (sum, item) => sum + (item.isEaten() ? item.value : 0),
      ),
      now: nowDateTime,
      lastMealTime: lastMealTime,
    );

    final List<DayResultModel> _dayResultsList2days =
    await calorieItemRepository.fetchDaysByProfile(activeProfile, 2);

    final List<ProfileModel> _profiles = await profileRepository.fetchAll();
    final List<WakingPeriodModel> wakingPeriods =
    await wakingPeriodRepository.fetchByProfile(activeProfile);
    final List<ProductModel> products = await productRepository.fetchAll();

    final WakingPeriodModel? currentWakingPeriod =
    await wakingPeriodRepository.findActual(activeProfile);
    final DateTime startDate =
    DateTime(nowDateTime.year, nowDateTime.month, nowDateTime.day);
    final DateTime endDate =
    DateTime(nowDateTime.year, nowDateTime.month, nowDateTime.day)
        .add(Duration(days: 1));

    List<CalorieItemModel> _calorieItems = [];

    if (currentWakingPeriod != null) {
      _calorieItems = await calorieItemRepository.fetchByWakingPeriodAndProfile(
          currentWakingPeriod, activeProfile);
    }

    emit(HomeFetched(
      nowDateTime: nowDateTime,
      periodCalorieItems: _calorieItems,
      todayCalorieItems: todayCalorieItems,
      rollingWindowCalorieItems: rollingWindowCalorieItems,
      days30: _dayResultsList30days,
      days2: _dayResultsList2days,
      profiles: _profiles,
      wakingPeriods: wakingPeriods,
      activeProfile: activeProfile,
      startDate: startDate,
      endDate: endDate,
      currentWakingPeriod: currentWakingPeriod,
      preparedCaloriesValue: _preparedCaloriesValue,
      products: products,
      recommendation: recommendation,
      equalizationSettings: _equalizationSettings,
    ));
  }
}