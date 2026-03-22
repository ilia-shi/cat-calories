import 'package:cat_calories/features/calorie_tracking/domain/day_result.dart';
import 'package:cat_calories/features/products/domain/product_model.dart';
import 'package:cat_calories/features/products/domain/product_category_model.dart';
import 'package:cat_calories/features/profile/domain/profile_model.dart';
import 'package:cat_calories/features/waking_periods/domain/waking_period_model.dart';
import 'package:cat_calories/features/products/product_repository.dart';
import 'package:cat_calories/features/products/product_category_repository.dart';
import 'package:cat_calories/features/profile/profile_repository.dart';
import 'package:cat_calories/features/waking_periods/waking_period_repository.dart';
import 'package:cat_calories/service/profile_resolver.dart';
import 'package:cat_calories/service/sync_service.dart';
import 'package:cat_calories/utils/expression_executor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/features/calorie_tracking/calorie_item_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/calorie_tracking/domain/calorie_item_model.dart';
import 'home_event.dart';
import 'package:cat_calories/features/calorie_tracking/domain/equalization_settings_model.dart';
import 'package:cat_calories/service/calorie_recommendation_service.dart';

class HomeBloc extends Bloc<AbstractHomeEvent, AbstractHomeState> {
  final locator = GetIt.instance;

  late ProductRepository productRepository = locator.get<ProductRepository>();
  late ProductCategoryRepository productCategoryRepository =
  locator.get<ProductCategoryRepository>();
  late CalorieItemRepository calorieItemRepository =
  locator.get<CalorieItemRepository>();
  late ProfileRepository profileRepository = locator.get<ProfileRepository>();
  late WakingPeriodRepository wakingPeriodRepository =
  locator.get<WakingPeriodRepository>();

  ProfileModel? _activeProfile;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  double _preparedCaloriesValue = 0;

  /// Store the last successful state for recovery
  HomeFetched? _lastSuccessfulState;

  HomeBloc() : super(HomeFetchingInProgress()) {
    // Register all event handlers
    on<CalorieItemListFetchingInProgressEvent>(_onCalorieItemListFetching);
    on<HomeErrorDismissedEvent>(_onErrorDismissed);
    on<CreatingCalorieItemEvent>(_onCreatingCalorieItem);
    on<CreatingCalorieItemWithNutritionEvent>(
        _onCreatingCalorieItemWithNutrition);
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
    on<EatEntirePackageEvent>(_onEatEntirePackage);
    on<ProductsResortEvent>(_onProductsResort);
    // Category events
    on<CreateProductCategoryEvent>(_onCreateProductCategory);
    on<UpdateProductCategoryEvent>(_onUpdateProductCategory);
    on<DeleteProductCategoryEvent>(_onDeleteProductCategory);
    on<ProductCategoriesResortEvent>(_onProductCategoriesResort);
    on<InitializeDefaultCategoriesEvent>(_onInitializeDefaultCategories);
  }

  _saveActiveProfile(ProfileModel profile) async {
    SharedPreferences prefs = await _prefs;
    prefs.setString(ProfileResolver.activeProfileKey, profile.id!);
    ProfileResolver.setActiveProfile(profile);
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

  Future<void> _onCreatingCalorieItemWithNutrition(
      CreatingCalorieItemWithNutritionEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();

    final CalorieItemModel calorieItem = CalorieItemModel(
      id: null,
      value: event.calories,
      sortOrder: 0,
      eatenAt: DateTime.now(),
      createdAt: DateTime.now(),
      description: event.description,
      profileId: _activeProfile!.id!,
      wakingPeriodId: event.wakingPeriod.id!,
      weightGrams: event.weightGrams,
      proteinGrams: event.proteinGrams,
      fatGrams: event.fatGrams,
      carbGrams: event.carbGrams,
      productId: event.productId,
    );

    await calorieItemRepository.offsetSortOrder();
    await calorieItemRepository.insert(calorieItem);

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
    event.calorieItem.updatedAt = DateTime.now();
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
    await calorieItemRepository.deleteByCreatedAtDay(
        event.date, event.profile);
    await _emitHomeData(emit);
  }

  Future<void> _onCalorieItemEating(
      CalorieItemEatingEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();
    final now = DateTime.now();
    event.calorieItem.eatenAt = now;
    event.calorieItem.updatedAt = now;
    await calorieItemRepository.update(event.calorieItem);
    await _emitHomeData(emit);
  }

  Future<void> _onProfileDeleting(
      ProfileDeletingEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    await _ensureActiveProfile();

    await profileRepository.delete(event.profile);

    final remainingProfiles = await profileRepository.fetchAll();

    if (event.profile.id == _activeProfile!.id) {
      if (remainingProfiles.isNotEmpty) {
        _activeProfile = remainingProfiles.first;
        await _saveActiveProfile(_activeProfile!);
      }
    }

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
    try {
      await _ensureActiveProfile();

      final product = ProductModel(
        id: null,
        profileId: _activeProfile!.id!,
        title: event.title,
        description: event.description,
        usesCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        barcode: event.barcode,
        caloriesPer100g: event.caloriesPer100g,
        proteinsPer100g: event.proteinsPer100g,
        fatsPer100g: event.fatsPer100g,
        carbsPer100g: event.carbsPer100g,
        packageWeightGrams: event.packageWeightGrams,
        categoryId: event.categoryId,
        sortOrder: 0,
      );

      await productRepository.offsetSortOrder();
      await productRepository.insert(product);
      await _emitHomeData(emit);
    } catch (e, stackTrace) {
      _emitError(emit, e, stackTrace);
    }
  }

  Future<void> _onDeleteProduct(
      DeleteProductEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    try {
      await _ensureActiveProfile();
      await productRepository.delete(event.product);
      await _emitHomeData(emit);
    } catch (e, stackTrace) {
      _emitError(emit, e, stackTrace);
    }
  }

  Future<void> _onUpdateProduct(
      UpdateProductEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    try {
      await _ensureActiveProfile();
      await productRepository.update(event.product);
      await _emitHomeData(emit);
    } catch (e, stackTrace) {
      _emitError(emit, e, stackTrace);
    }
  }

  Future<void> _onEatProduct(
      EatProductEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    try {
      await _ensureActiveProfile();

      final product = event.product;
      final weightGrams = event.weightGrams;

      // Calculate nutrition values based on weight
      final calories = product.calculateCalories(weightGrams) ?? 0;
      final protein = product.calculateProtein(weightGrams);
      final fat = product.calculateFat(weightGrams);
      final carbs = product.calculateCarbs(weightGrams);

      final CalorieItemModel calorieItem = CalorieItemModel(
        id: null,
        value: calories,
        sortOrder: 0,
        eatenAt: DateTime.now(),
        createdAt: DateTime.now(),
        description: product.title,
        profileId: _activeProfile!.id!,
        wakingPeriodId: event.wakingPeriod.id!,
        weightGrams: weightGrams,
        proteinGrams: protein,
        fatGrams: fat,
        carbGrams: carbs,
        productId: product.id,
      );

      await calorieItemRepository.offsetSortOrder();
      await calorieItemRepository.insert(calorieItem);

      // Update product usage statistics
      await productRepository.recordUsage(product);

      event.callback(calorieItem);
      await _emitHomeData(emit);
    } catch (e, stackTrace) {
      _emitError(emit, e, stackTrace);
    }
  }

  Future<void> _onEatEntirePackage(
      EatEntirePackageEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    try {
      await _ensureActiveProfile();

      final product = event.product;
      if (!product.hasPackageWeight) {
        throw Exception('Product does not have package weight defined');
      }

      final weightGrams = product.packageWeightGrams!;

      // Calculate nutrition values based on package weight
      final calories = product.calculateCalories(weightGrams) ?? 0;
      final protein = product.calculateProtein(weightGrams);
      final fat = product.calculateFat(weightGrams);
      final carbs = product.calculateCarbs(weightGrams);

      final CalorieItemModel calorieItem = CalorieItemModel(
        id: null,
        value: calories,
        sortOrder: 0,
        eatenAt: DateTime.now(),
        createdAt: DateTime.now(),
        description: '${product.title} (entire package)',
        profileId: _activeProfile!.id!,
        wakingPeriodId: event.wakingPeriod.id!,
        weightGrams: weightGrams,
        proteinGrams: protein,
        fatGrams: fat,
        carbGrams: carbs,
        productId: product.id,
      );

      await calorieItemRepository.offsetSortOrder();
      await calorieItemRepository.insert(calorieItem);

      // Update product usage statistics
      await productRepository.recordUsage(product);

      event.callback(calorieItem);
      await _emitHomeData(emit);
    } catch (e, stackTrace) {
      _emitError(emit, e, stackTrace);
    }
  }

  Future<void> _onProductsResort(
      ProductsResortEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    try {
      await _ensureActiveProfile();
      await productRepository.resort(event.products);
      await _emitHomeData(emit);
    } catch (e, stackTrace) {
      _emitError(emit, e, stackTrace);
    }
  }

  // ============================================================================
  // Category Event Handlers
  // ============================================================================

  Future<void> _onCreateProductCategory(
      CreateProductCategoryEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    try {
      await _ensureActiveProfile();

      final category = ProductCategoryModel(
        id: null,
        name: event.name,
        iconName: event.iconName,
        colorHex: event.colorHex,
        sortOrder: 0,
        profileId: _activeProfile!.id!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await productCategoryRepository.insert(category);
      await _emitHomeData(emit);
    } catch (e, stackTrace) {
      _emitError(emit, e, stackTrace);
    }
  }

  Future<void> _onUpdateProductCategory(
      UpdateProductCategoryEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    try {
      await _ensureActiveProfile();
      await productCategoryRepository.update(event.category);
      await _emitHomeData(emit);
    } catch (e, stackTrace) {
      _emitError(emit, e, stackTrace);
    }
  }

  Future<void> _onDeleteProductCategory(
      DeleteProductCategoryEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    try {
      await _ensureActiveProfile();
      await productCategoryRepository.delete(event.category);
      await _emitHomeData(emit);
    } catch (e, stackTrace) {
      _emitError(emit, e, stackTrace);
    }
  }

  Future<void> _onProductCategoriesResort(
      ProductCategoriesResortEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    try {
      await _ensureActiveProfile();
      await productCategoryRepository.resort(event.categories);
      await _emitHomeData(emit);
    } catch (e, stackTrace) {
      _emitError(emit, e, stackTrace);
    }
  }

  Future<void> _onInitializeDefaultCategories(
      InitializeDefaultCategoriesEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    try {
      await _ensureActiveProfile();
      await productCategoryRepository.createDefaultCategoriesIfNeeded(
          _activeProfile!);
      await _emitHomeData(emit);
    } catch (e, stackTrace) {
      _emitError(emit, e, stackTrace);
    }
  }

  EqualizationSettingsModel _equalizationSettings = EqualizationSettingsModel();

  /// Fetch calorie items for the rolling window (last 48 hours).
  Future<List<CalorieItemModel>> _fetchRollingWindowItems() async {
    final now = DateTime.now();
    final List<CalorieItemModel> allItems = [];

    // Fetch today's items
    final todayItems = await calorieItemRepository.fetchByCreatedAtDay(now);
    allItems.addAll(todayItems);

    // Fetch yesterday's items
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayItems =
    await calorieItemRepository.fetchByCreatedAtDay(yesterday);
    allItems.addAll(yesterdayItems);

    // Fetch day before yesterday (to ensure full 48h coverage for edge cases)
    final dayBeforeYesterday = now.subtract(const Duration(days: 2));
    final dayBeforeItems =
    await calorieItemRepository.fetchByCreatedAtDay(dayBeforeYesterday);
    allItems.addAll(dayBeforeItems);

    // Remove duplicates by ID (in case of overlap)
    final seen = <String>{};
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
    try {
      final ProfileModel activeProfile = _activeProfile!;

      final DateTime nowDateTime = DateTime.now();

      // Calculate recommendation
      final recommendationService = CalorieRecommendationService(
        EqualizationSettingsModel(
          baseCalorieGoal: activeProfile.caloriesLimitGoal,
        ),
      );

      List<CalorieItemModel> todayCalorieItems =
      await calorieItemRepository.fetchByCreatedAtDay(nowDateTime);

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
      final List<ProductModel> products =
      await productRepository.fetchByProfile(activeProfile);
      final List<ProductCategoryModel> productCategories =
      await productCategoryRepository.fetchByProfile(activeProfile);

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

      final newState = HomeFetched(
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
        productCategories: productCategories,
        recommendation: recommendation,
        equalizationSettings: _equalizationSettings,
      );

      _lastSuccessfulState = newState;
      emit(newState);

      // Fire-and-forget sync (guarded by _syncing flag + enabled check)
      locator.get<SyncService>().sync();
    } catch (e, stackTrace) {
      _emitError(emit, e, stackTrace);
    }
  }

  /// Emit an error state with real error message and stack trace
  void _emitError(
      Emitter<AbstractHomeState> emit,
      dynamic error,
      StackTrace stackTrace,
      ) {
    final errorDetails = StringBuffer();
    errorDetails.writeln('${error.runtimeType}: $error');
    errorDetails.writeln('');
    errorDetails.writeln('Stack trace:');
    errorDetails.writeln(stackTrace.toString());

    emit(HomeError(
      message: error.toString(),
      technicalDetails: errorDetails.toString(),
      originalError: error,
      stackTrace: stackTrace,
      canRetry: true,
      previousState: _lastSuccessfulState,
    ));
  }

  /// Handle error dismissed event
  Future<void> _onErrorDismissed(
      HomeErrorDismissedEvent event,
      Emitter<AbstractHomeState> emit,
      ) async {
    if (event.retry) {
      // Retry loading data
      emit(HomeFetchingInProgress());
      await _emitHomeData(emit);
    } else if (_lastSuccessfulState != null) {
      // Restore previous state
      emit(_lastSuccessfulState!);
    } else {
      // No previous state, try loading
      emit(HomeFetchingInProgress());
      await _emitHomeData(emit);
    }
  }
}