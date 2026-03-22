import 'dart:async';
import 'dart:convert';

import 'package:cat_calories/features/calorie_tracking/domain/calorie_item_model.dart';
import 'package:cat_calories/features/products/domain/product_category_model.dart';
import 'package:cat_calories/features/products/domain/product_model.dart';
import 'package:cat_calories/features/profile/domain/profile_model.dart';
import 'package:cat_calories/features/waking_periods/domain/waking_period_model.dart';
import 'package:cat_calories/features/calorie_tracking/calorie_item_repository.dart';
import 'package:cat_calories/features/products/product_category_repository.dart';
import 'package:cat_calories/features/products/product_repository.dart';
import 'package:cat_calories/features/profile/profile_repository.dart';
import 'package:cat_calories/features/waking_periods/waking_period_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  static const String _enabledKey = 'sync_enabled';
  static const String _serverUrlKey = 'sync_server_url';
  static const String _tokenKey = 'sync_token';
  static const String _lastSyncedAtKey = 'sync_last_synced_at';
  static const String _emailKey = 'sync_email';
  static const String _passwordKey = 'sync_password';

  final _locator = GetIt.instance;
  StreamSubscription? _connectivitySubscription;
  bool _syncing = false;

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<String> get serverUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? '';
  }

  Future<String> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) ?? '';
  }

  Future<String> get email async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? '';
  }

  Future<String> get password async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey) ?? '';
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (enabled) {
      _startConnectivityListener();
    } else {
      _stopConnectivityListener();
    }
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url.trimRight());
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Login to the remote server and store the token.
  Future<String?> login(String serverUrl, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$serverUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      final tok = data['token'] as String?;
      if (tok != null) {
        await setToken(tok);
        await setServerUrl(serverUrl);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_emailKey, email);
        await prefs.setString(_passwordKey, password);
      }
      return tok;
    } catch (e) {
      print('SyncService login error: $e');
      return null;
    }
  }

  /// Re-login using stored credentials and get a fresh token.
  Future<bool> reconnect() async {
    final url = await serverUrl;
    final em = await email;
    final pw = await password;
    if (url.isEmpty || em.isEmpty || pw.isEmpty) return false;
    final tok = await login(url, em, pw);
    return tok != null;
  }

  /// Start listening for connectivity changes to auto-sync.
  void _startConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final hasConnection = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
      if (hasConnection) {
        sync();
      }
    });
  }

  void _stopConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Initialize: start connectivity listener if sync is enabled.
  Future<void> init() async {
    if (await isEnabled) {
      _startConnectivityListener();
    }
  }

  void dispose() {
    _stopConnectivityListener();
  }

  /// Perform a sync with the remote server.
  Future<bool> sync() async {
    if (_syncing) return false;
    if (!await isEnabled) return false;

    final url = await serverUrl;
    final tok = await token;
    if (url.isEmpty || tok.isEmpty) return false;

    _syncing = true;
    try {
      return await _doSync(url, tok);
    } catch (e) {
      print('SyncService sync error: $e');
      return false;
    } finally {
      _syncing = false;
    }
  }

  Future<bool> _doSync(String serverUrl, String authToken) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncedStr = prefs.getString(_lastSyncedAtKey);

    final calorieRepo = _locator.get<CalorieItemRepository>();
    final profileRepo = _locator.get<ProfileRepository>();
    final wakingPeriodRepo = _locator.get<WakingPeriodRepository>();
    final productRepo = _locator.get<ProductRepository>();
    // Gather all local data
    final allItems = await calorieRepo.findAll();
    final allProfiles = await profileRepo.fetchAll();
    final allWakingPeriods = await wakingPeriodRepo.fetchAll();
    final allProducts = await productRepo.fetchAll();
    // ProductCategoryRepository doesn't have fetchAll, query DB directly
    final allCategoryRows = await _fetchAllProductCategories();

    // Build sync request
    final requestBody = <String, dynamic>{};

    if (lastSyncedStr != null) {
      requestBody['last_synced_at'] = lastSyncedStr;
    }

    requestBody['profiles'] = allProfiles.map((p) => _profileToSyncJson(p)).toList();
    requestBody['waking_periods'] = allWakingPeriods.map((wp) => _wakingPeriodToSyncJson(wp)).toList();
    requestBody['product_categories'] = allCategoryRows.map((c) => _productCategoryToSyncJson(c)).toList();
    requestBody['products'] = allProducts.map((p) => _productToSyncJson(p)).toList();
    requestBody['calorie_items'] = allItems.map((item) => _itemToSyncJson(item)).toList();

    final res = await http.post(
      Uri.parse('$serverUrl/api/sync'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(requestBody),
    );

    if (res.statusCode != 200) {
      print('SyncService: server returned ${res.statusCode}: ${res.body}');
      return false;
    }

    final response = jsonDecode(res.body) as Map<String, dynamic>;

    // Apply server changes locally — profiles first
    final serverProfiles = response['profiles'] as List<dynamic>? ?? [];
    for (final profileJson in serverProfiles) {
      final serverProfile = _profileFromSyncJson(profileJson as Map<String, dynamic>);
      final existingProfiles = await profileRepo.fetchAll();
      final existing = existingProfiles.where((p) => p.id == serverProfile.id).firstOrNull;
      if (existing == null) {
        await profileRepo.insert(serverProfile);
      } else {
        await profileRepo.update(serverProfile);
      }
    }

    final serverItems = response['calorie_items'] as List<dynamic>? ?? [];
    for (final itemJson in serverItems) {
      final serverItem = _itemFromSyncJson(itemJson as Map<String, dynamic>);
      if (serverItem.id == null) continue;

      final existing = await calorieRepo.find(serverItem.id!);
      if (existing == null) {
        await calorieRepo.insert(serverItem);
      } else if (serverItem.updatedAt.isAfter(existing.updatedAt) ||
          serverItem.updatedAt.isAtSameMomentAs(existing.updatedAt)) {
        await calorieRepo.update(serverItem);
      }
    }

    // Store sync timestamp
    final syncedAt = response['synced_at'] as String?;
    if (syncedAt != null) {
      await prefs.setString(_lastSyncedAtKey, syncedAt);
    }

    print('SyncService: sync completed successfully');
    return true;
  }

  Future<List<ProductCategoryModel>> _fetchAllProductCategories() async {
    final repo = _locator.get<ProductCategoryRepository>();
    // Fetch categories for all profiles
    final profiles = await _locator.get<ProfileRepository>().fetchAll();
    final categories = <ProductCategoryModel>[];
    for (final p in profiles) {
      categories.addAll(await repo.fetchByProfile(p));
    }
    return categories;
  }

  // ---- Profile serialization ----

  Map<String, dynamic> _profileToSyncJson(ProfileModel profile) {
    return {
      'id': profile.id,
      'name': profile.name,
      'waking_time_seconds': profile.wakingTimeSeconds,
      'calories_limit_goal': profile.caloriesLimitGoal.round(),
      'created_at': profile.createdAt.toUtc().toIso8601String(),
      'updated_at': profile.updatedAt.toUtc().toIso8601String(),
    };
  }

  ProfileModel _profileFromSyncJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      wakingTimeSeconds: json['waking_time_seconds'] as int? ?? 0,
      caloriesLimitGoal: (json['calories_limit_goal'] as num?)?.toDouble() ?? 2000,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // ---- WakingPeriod serialization ----

  Map<String, dynamic> _wakingPeriodToSyncJson(WakingPeriodModel wp) {
    return {
      'id': wp.id,
      'profile_id': wp.profileId,
      'description': wp.description ?? '',
      'calories_value': wp.caloriesValue,
      'calories_limit_goal': wp.caloriesLimitGoal.round(),
      'expected_waking_time_sec': wp.expectedWakingTimeSeconds,
      'started_at': wp.startedAt.toUtc().toIso8601String(),
      'ended_at': wp.endedAt?.toUtc().toIso8601String(),
      'created_at': wp.createdAt.toUtc().toIso8601String(),
      'updated_at': wp.updatedAt.toUtc().toIso8601String(),
    };
  }

  // ---- ProductCategory serialization ----

  Map<String, dynamic> _productCategoryToSyncJson(ProductCategoryModel c) {
    return {
      'id': c.id,
      'profile_id': c.profileId,
      'name': c.name,
      'icon_name': c.iconName ?? '',
      'color_hex': c.colorHex ?? '',
      'sort_order': c.sortOrder,
      'created_at': c.createdAt.toUtc().toIso8601String(),
      'updated_at': c.updatedAt.toUtc().toIso8601String(),
    };
  }

  // ---- Product serialization ----

  Map<String, dynamic> _productToSyncJson(ProductModel p) {
    return {
      'id': p.id,
      'profile_id': p.profileId,
      'category_id': p.categoryId,
      'title': p.title,
      'description': p.description ?? '',
      'barcode': p.barcode,
      'calories_per_100g': p.caloriesPer100g,
      'proteins_per_100g': p.proteinsPer100g,
      'fats_per_100g': p.fatsPer100g,
      'carbs_per_100g': p.carbsPer100g,
      'package_weight_g': p.packageWeightGrams,
      'uses_count': p.usesCount,
      'last_used_at': p.lastUsedAt?.toUtc().toIso8601String(),
      'sort_order': p.sortOrder,
      'created_at': p.createdAt.toUtc().toIso8601String(),
      'updated_at': p.updatedAt.toUtc().toIso8601String(),
    };
  }

  // ---- CalorieItem serialization ----

  Map<String, dynamic> _itemToSyncJson(CalorieItemModel item) {
    return {
      'id': item.id,
      'profile_id': item.profileId,
      'waking_period_id': item.wakingPeriodId,
      'product_id': item.productId,
      'value': item.value,
      'description': item.description ?? '',
      'sort_order': item.sortOrder,
      'weight_grams': item.weightGrams,
      'protein_grams': item.proteinGrams,
      'fat_grams': item.fatGrams,
      'carb_grams': item.carbGrams,
      'eaten_at': (item.eatenAt ?? item.createdAt).toUtc().toIso8601String(),
      'created_at': item.createdAt.toUtc().toIso8601String(),
      'updated_at': item.updatedAt.toUtc().toIso8601String(),
    };
  }

  CalorieItemModel _itemFromSyncJson(Map<String, dynamic> json) {
    return CalorieItemModel(
      id: json['id']?.toString(),
      value: (json['value'] as num).toDouble(),
      description: json['description'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      eatenAt: json['eaten_at'] != null ? DateTime.parse(json['eaten_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      profileId: json['profile_id'] as int,
      wakingPeriodId: json['waking_period_id'] as int?,
      weightGrams: (json['weight_grams'] as num?)?.toDouble(),
      proteinGrams: (json['protein_grams'] as num?)?.toDouble(),
      fatGrams: (json['fat_grams'] as num?)?.toDouble(),
      carbGrams: (json['carb_grams'] as num?)?.toDouble(),
      productId: json['product_id'] as String?,
    );
  }
}
