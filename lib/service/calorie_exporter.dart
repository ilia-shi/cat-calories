import 'dart:convert';
import 'dart:io';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:cat_calories/models/profile_model.dart';
import 'package:cat_calories/models/product_model.dart';
import 'package:cat_calories/models/waking_period_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

final class CalorieExporter {
  static Future<String> exportToJson({
    required List<CalorieItemModel> calorieItems,
    required ProfileModel profile,
    List<ProductModel>? products,
    List<WakingPeriodModel>? wakingPeriods,
    String? exportType,
  }) async {
    final exportData = {
      'export_metadata': {
        'exported_at': DateTime.now().toIso8601String(),
        'export_type': exportType ?? 'full',
        'app_name': 'Cat Calories',
        'version': '1.0.0',
        'total_items': calorieItems.length,
      },
      'profile': {
        'id': profile.id,
        'name': profile.name,
        'calories_limit_goal': profile.caloriesLimitGoal,
        'waking_time_seconds': profile.wakingTimeSeconds,
      },
      'calorie_items': calorieItems.map((item) => {
        'id': item.id,
        'value': item.value,
        'description': item.description,
        'sort_order': item.sortOrder,
        'eaten_at': item.eatenAt?.toIso8601String(),
        'created_at': item.createdAt.toIso8601String(),
        'profile_id': item.profileId,
        'waking_period_id': item.wakingPeriodId,
        'is_eaten': item.isEaten(),
      }).toList(),
      if (products != null && products.isNotEmpty)
        'products': products.map((product) => {
          'id': product.id,
          'title': product.title,
          'description': product.description,
          'calorie_content': product.calorieContent,
          'proteins': product.proteins,
          'fats': product.fats,
          'carbohydrates': product.carbohydrates,
          'barcode': product.barcode,
          'uses_count': product.usesCount,
        }).toList(),
      if (wakingPeriods != null && wakingPeriods.isNotEmpty)
        'waking_periods': wakingPeriods.map((period) => {
          'id': period.id,
          'description': period.description,
          'started_at': period.startedAt.toIso8601String(),
          'ended_at': period.endedAt?.toIso8601String(),
          'calories_value': period.caloriesValue,
          'calories_limit_goal': period.caloriesLimitGoal,
        }).toList(),
    };

    // Convert to pretty-printed JSON
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    // Generate filename with timestamp
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final fileName = 'cat_calories_export_$timestamp.json';

    // Get the documents directory
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';

    // Write to file
    final file = File(filePath);
    await file.writeAsString(jsonString);

    return filePath;
  }

  /// Export and share the JSON file using SharePlus 12.0.1
  static Future<ShareResult> exportAndShare({
    required List<CalorieItemModel> calorieItems,
    required ProfileModel profile,
    List<ProductModel>? products,
    List<WakingPeriodModel>? wakingPeriods,
    String? exportType,
  }) async {
    final filePath = await exportToJson(
      calorieItems: calorieItems,
      profile: profile,
      products: products,
      wakingPeriods: wakingPeriods,
      exportType: exportType,
    );

    // Share the file using the new SharePlus 12.0.1 API
    return await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: 'Cat Calories Export',
        text: 'My calorie tracking data export',
      ),
    );
  }

  /// Export only today's calorie items
  static Future<ShareResult> exportTodayAndShare({
    required List<CalorieItemModel> todayCalorieItems,
    required ProfileModel profile,
  }) async {
    return await exportAndShare(
      calorieItems: todayCalorieItems,
      profile: profile,
      exportType: 'today',
    );
  }

  /// Export current period's calorie items
  static Future<ShareResult> exportPeriodAndShare({
    required List<CalorieItemModel> periodCalorieItems,
    required ProfileModel profile,
    WakingPeriodModel? currentWakingPeriod,
  }) async {
    return await exportAndShare(
      calorieItems: periodCalorieItems,
      profile: profile,
      wakingPeriods: currentWakingPeriod != null ? [currentWakingPeriod] : null,
      exportType: 'current_period',
    );
  }

  /// Get export statistics summary
  static Map<String, dynamic> getExportSummary(List<CalorieItemModel> items) {
    double totalCalories = 0;
    double positiveCalories = 0;
    double negativeCalories = 0;
    int eatenCount = 0;

    for (final item in items) {
      if (item.isEaten()) {
        eatenCount++;
        totalCalories += item.value;
        if (item.value > 0) {
          positiveCalories += item.value;
        } else {
          negativeCalories += item.value;
        }
      }
    }

    return {
      'total_items': items.length,
      'eaten_items': eatenCount,
      'total_calories': totalCalories,
      'positive_calories': positiveCalories,
      'negative_calories': negativeCalories,
    };
  }
}