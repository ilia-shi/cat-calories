/// Модели данных для алгоритма стабилизации калорий

/// Запись о потреблении калорий
class CalorieEntry {
  final DateTime timestamp;
  final double calories;
  final String? note;

  const CalorieEntry({
    required this.timestamp,
    required this.calories,
    this.note,
  });

  @override
  String toString() =>
      'CalorieEntry(${timestamp.toIso8601String()}, $calories kcal)';

  CalorieEntry copyWith({
    DateTime? timestamp,
    double? calories,
    String? note,
  }) {
    return CalorieEntry(
      timestamp: timestamp ?? this.timestamp,
      calories: calories ?? this.calories,
      note: note ?? this.note,
    );
  }
}

/// Уровень серьёзности предупреждения
enum WarningSeverity {
  info,
  warning,
  critical,
}

/// Тип предупреждения
enum WarningType {
  overeating,
  fasting,
  rapidConsumption,
  debt,
  belowMinimum,
}

/// Предупреждение системы
class Warning {
  final WarningType type;
  final String message;
  final WarningSeverity severity;

  const Warning({
    required this.type,
    required this.message,
    required this.severity,
  });

  @override
  String toString() => 'Warning($type: $message [$severity])';
}

/// Рекомендация по следующему приёму пищи
class MealSuggestion {
  /// Рекомендуемое время следующего приёма
  final DateTime suggestedTime;

  /// Рекомендуемое количество калорий
  final double suggestedCalories;

  /// Минимальное количество калорий
  final double minCalories;

  /// Максимальное количество калорий
  final double maxCalories;

  /// Причина/объяснение рекомендации
  final String reason;

  const MealSuggestion({
    required this.suggestedTime,
    required this.suggestedCalories,
    required this.minCalories,
    required this.maxCalories,
    required this.reason,
  });

  @override
  String toString() =>
      'MealSuggestion(time: $suggestedTime, calories: $suggestedCalories ($minCalories-$maxCalories))';
}

/// Полная рекомендация на текущий период
class DailyRecommendation {
  /// Скорректированная цель калорий
  final double adjustedTarget;

  /// Уже потреблено калорий
  final double consumed;

  /// Осталось калорий
  final double remaining;

  /// Рекомендация по следующему приёму пищи
  final MealSuggestion nextMeal;

  /// Список предупреждений
  final List<Warning> warnings;

  /// Накопленный "долг" калорий
  final double calorieDebt;

  /// Базовая цель (без корректировки)
  final double baseTarget;

  /// Размер компенсации
  final double compensation;

  const DailyRecommendation({
    required this.adjustedTarget,
    required this.consumed,
    required this.remaining,
    required this.nextMeal,
    required this.warnings,
    required this.calorieDebt,
    required this.baseTarget,
    required this.compensation,
  });

  /// Процент выполнения дневной нормы
  double get progressPercent =>
      adjustedTarget > 0 ? (consumed / adjustedTarget * 100).clamp(0, 200) : 0;

  /// Есть ли критические предупреждения
  bool get hasCriticalWarnings =>
      warnings.any((w) => w.severity == WarningSeverity.critical);

  @override
  String toString() => '''
DailyRecommendation:
  Target: $adjustedTarget kcal (base: $baseTarget, compensation: -$compensation)
  Consumed: $consumed kcal
  Remaining: $remaining kcal
  Debt: $calorieDebt kcal
  Warnings: ${warnings.length}
  Next meal: ${nextMeal.suggestedCalories} kcal at ${nextMeal.suggestedTime}
''';
}

/// Настройки алгоритма стабилизации
class StabilizerSettings {
  // === Основные параметры цели ===

  /// Целевое потребление калорий в день
  final double targetDailyCalories;

  /// Базовое окно для расчёта "дневной" нормы (в часах)
  final double windowHours;

  // === Параметры компенсации ===

  /// Коэффициент компенсации (0.0 - 1.0)
  /// Какую долю превышения компенсировать
  final double compensationRate;

  /// Максимальное снижение нормы в день (ккал)
  final double maxCompensationPerDay;

  /// Период затухания долга (дни)
  /// За сколько дней "долг" полностью обнуляется
  final int compensationDecayDays;

  // === Защитные ограничения ===

  /// Минимальное потребление калорий в день
  final double minDailyCalories;

  /// Максимальное потребление калорий в день
  final double maxDailyCalories;

  /// Максимальное потребление калорий в час (порог переедания)
  final double maxCaloriesPerHour;

  /// Максимальное потребление калорий за один приём
  final double maxCaloriesPerMeal;

  // === Параметры приёмов пищи ===

  /// Минимальный интервал между приёмами пищи (часы)
  final double minMealInterval;

  /// Максимальное время без еды (часы)
  final double maxFastingHours;

  /// Желаемое количество приёмов пищи в день
  final int idealMealsPerDay;

  /// Допустимый разброс размера порций (0.0 - 1.0)
  final double mealSizeVariance;

  // === Параметры сглаживания ===

  /// Период полураспада истории (дни)
  /// Через сколько дней влияние данных падает вдвое
  final double historyDecayHalfLife;

  /// Окно повышенного внимания к последним данным (часы)
  final double recentHoursWeight;

  // === Параметры группировки приёмов пищи ===

  /// Интервал группировки записей в один приём пищи (минуты)
  final int mealGroupingMinutes;

  const StabilizerSettings({
    this.targetDailyCalories = 2000,
    this.windowHours = 24,
    this.compensationRate = 0.5,
    this.maxCompensationPerDay = 300,
    this.compensationDecayDays = 7,
    this.minDailyCalories = 1200,
    this.maxDailyCalories = 3000,
    this.maxCaloriesPerHour = 800,
    this.maxCaloriesPerMeal = 1000,
    this.minMealInterval = 2,
    this.maxFastingHours = 8,
    this.idealMealsPerDay = 4,
    this.mealSizeVariance = 0.3,
    this.historyDecayHalfLife = 3,
    this.recentHoursWeight = 6,
    this.mealGroupingMinutes = 30,
  });

  /// Мягкий режим (для начинающих)
  factory StabilizerSettings.soft() => const StabilizerSettings(
    compensationRate: 0.3,
    maxCompensationPerDay: 150,
    minDailyCalories: 1500,
    maxFastingHours: 6,
  );

  /// Строгий режим (для опытных)
  factory StabilizerSettings.strict() => const StabilizerSettings(
    compensationRate: 0.7,
    maxCompensationPerDay: 400,
    minDailyCalories: 1200,
    maxFastingHours: 10,
  );

  /// Режим набора массы
  factory StabilizerSettings.bulking() => const StabilizerSettings(
    targetDailyCalories: 2800,
    compensationRate: 0.2,
    minDailyCalories: 2200,
    maxDailyCalories: 3500,
  );

  /// Режим сушки/похудения
  factory StabilizerSettings.cutting() => const StabilizerSettings(
    targetDailyCalories: 1600,
    compensationRate: 0.6,
    maxCompensationPerDay: 200,
    minDailyCalories: 1200,
    maxDailyCalories: 2000,
  );

  StabilizerSettings copyWith({
    double? targetDailyCalories,
    double? windowHours,
    double? compensationRate,
    double? maxCompensationPerDay,
    int? compensationDecayDays,
    double? minDailyCalories,
    double? maxDailyCalories,
    double? maxCaloriesPerHour,
    double? maxCaloriesPerMeal,
    double? minMealInterval,
    double? maxFastingHours,
    int? idealMealsPerDay,
    double? mealSizeVariance,
    double? historyDecayHalfLife,
    double? recentHoursWeight,
    int? mealGroupingMinutes,
  }) {
    return StabilizerSettings(
      targetDailyCalories: targetDailyCalories ?? this.targetDailyCalories,
      windowHours: windowHours ?? this.windowHours,
      compensationRate: compensationRate ?? this.compensationRate,
      maxCompensationPerDay:
      maxCompensationPerDay ?? this.maxCompensationPerDay,
      compensationDecayDays:
      compensationDecayDays ?? this.compensationDecayDays,
      minDailyCalories: minDailyCalories ?? this.minDailyCalories,
      maxDailyCalories: maxDailyCalories ?? this.maxDailyCalories,
      maxCaloriesPerHour: maxCaloriesPerHour ?? this.maxCaloriesPerHour,
      maxCaloriesPerMeal: maxCaloriesPerMeal ?? this.maxCaloriesPerMeal,
      minMealInterval: minMealInterval ?? this.minMealInterval,
      maxFastingHours: maxFastingHours ?? this.maxFastingHours,
      idealMealsPerDay: idealMealsPerDay ?? this.idealMealsPerDay,
      mealSizeVariance: mealSizeVariance ?? this.mealSizeVariance,
      historyDecayHalfLife: historyDecayHalfLife ?? this.historyDecayHalfLife,
      recentHoursWeight: recentHoursWeight ?? this.recentHoursWeight,
      mealGroupingMinutes: mealGroupingMinutes ?? this.mealGroupingMinutes,
    );
  }

  /// Валидация настроек
  List<String> validate() {
    final errors = <String>[];

    if (targetDailyCalories <= 0) {
      errors.add('targetDailyCalories должен быть положительным');
    }
    if (minDailyCalories >= targetDailyCalories) {
      errors.add('minDailyCalories должен быть меньше targetDailyCalories');
    }
    if (maxDailyCalories <= targetDailyCalories) {
      errors.add('maxDailyCalories должен быть больше targetDailyCalories');
    }
    if (compensationRate < 0 || compensationRate > 1) {
      errors.add('compensationRate должен быть от 0 до 1');
    }
    if (mealSizeVariance < 0 || mealSizeVariance > 1) {
      errors.add('mealSizeVariance должен быть от 0 до 1');
    }
    if (minMealInterval >= maxFastingHours) {
      errors.add('minMealInterval должен быть меньше maxFastingHours');
    }
    if (idealMealsPerDay <= 0) {
      errors.add('idealMealsPerDay должен быть положительным');
    }

    return errors;
  }

  bool get isValid => validate().isEmpty;
}