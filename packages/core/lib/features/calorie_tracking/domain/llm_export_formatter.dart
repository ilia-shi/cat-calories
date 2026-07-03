import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';

import './calorie_record.dart';
import './meal.dart';

/// Formats calorie history as a compact markdown document meant to be pasted
/// into (or read by) an external LLM for nutrition analysis.
///
/// Pure formatting, no I/O — reusable by the app, web client and server.
/// Increment A of docs/plans/master_plan.md; later increments (meals, costs)
/// only enrich this output, they must never be required for it to work.
final class LlmExportFormatter {
  const LlmExportFormatter();

  /// Keep the sparseness warning: fields are logged opportunistically and the
  /// LLM must not treat absent data as zero.
  static const String defaultPreamble =
      'This is a personal food log exported from the Cat Calories app.\n'
      'Data is logged opportunistically: weights, macros and product links '
      'may be missing — treat missing values as unknown, not zero.\n'
      'Useful questions to ask about this log: suggest tomorrow\'s meals from '
      'the products listed at the end; how to make this nutrition healthier, '
      'cheaper, tastier and less time-consuming to cook.';

  /// A product price older than this is flagged in the export so the LLM
  /// (and the user) treat its cost math with suspicion.
  static const Duration stalePriceAfter = Duration(days: 90);

  String format({
    required Profile profile,
    required List<CalorieRecord> records,
    List<Product> products = const [],
    List<Meal> meals = const [],
    String? preamble,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final productsById = <String, Product>{
      for (final product in products)
        if (product.id != null) product.id!: product,
    };
    final mealsById = <String, Meal>{
      for (final meal in meals)
        if (meal.id != null) meal.id!: meal,
    };

    final eaten = records.where((r) => r.eatenAt != null).toList()
      ..sort((a, b) => a.eatenAt!.compareTo(b.eatenAt!));
    final planned = records.where((r) => r.eatenAt == null).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final buffer = StringBuffer('# Cat Calories — nutrition log\n');
    buffer.writeln(
        'Profile: ${profile.name} · Daily goal: ${_num(profile.caloriesLimitGoal)} kcal');
    if (eaten.isNotEmpty) {
      buffer.writeln(
          'Period: ${_date(eaten.first.eatenAt!)} .. ${_date(eaten.last.eatenAt!)}');
    }
    final currencies = _currenciesIn(records, products);
    if (currencies.isNotEmpty) {
      buffer.writeln(
          'Costs are snapshotted at eating time in the currency then in use '
          '(${currencies.join(', ')}); a missing cost is unknown, not zero.');
    }
    buffer
      ..writeln()
      ..writeln(preamble ?? defaultPreamble);

    _writeDays(buffer, eaten, productsById, mealsById);
    _writeWeeklySummary(buffer, eaten);
    _writePlanned(buffer, planned, productsById);
    _writeProducts(buffer, products, effectiveNow);

    return buffer.toString();
  }

  /// Per-week rollups (weeks start Monday) so the LLM can reason about
  /// trends without re-deriving them from the day sections.
  void _writeWeeklySummary(StringBuffer buffer, List<CalorieRecord> eaten) {
    if (eaten.isEmpty) {
      return;
    }

    final byWeek = <DateTime, List<CalorieRecord>>{};
    for (final record in eaten) {
      final at = record.eatenAt!;
      final day = DateTime(at.year, at.month, at.day);
      final monday = day.subtract(Duration(days: day.weekday - 1));
      byWeek.putIfAbsent(monday, () => []).add(record);
    }

    buffer
      ..writeln()
      ..writeln('## Weekly summary');
    for (final entry in byWeek.entries) {
      final records = entry.value;
      final days = <DateTime>{
        for (final record in records)
          DateTime(record.eatenAt!.year, record.eatenAt!.month,
              record.eatenAt!.day),
      };
      final total = records.fold<double>(0, (sum, r) => sum + r.value);
      final parts = <String>[
        '${days.length} day${days.length == 1 ? '' : 's'} logged',
        'avg ${_num(total / days.length)} kcal/day',
        ..._costSumsParts(records),
      ];
      final sunday = entry.key.add(const Duration(days: 6));
      buffer.writeln(
          '- ${_date(entry.key)} .. ${_date(sunday)}: ${parts.join(' · ')}');
    }
  }

  void _writeDays(StringBuffer buffer, List<CalorieRecord> eaten,
      Map<String, Product> productsById, Map<String, Meal> mealsById) {
    final byDay = <DateTime, List<CalorieRecord>>{};
    for (final record in eaten) {
      final at = record.eatenAt!;
      final day = DateTime(at.year, at.month, at.day);
      byDay.putIfAbsent(day, () => []).add(record);
    }

    for (final entry in byDay.entries) {
      final records = entry.value;
      buffer
        ..writeln()
        ..writeln(
            '## ${_date(entry.key)} — total ${_total(records)}${_macroSums(records)}${_costSums(records)}');
      _writeDayRecords(buffer, records, productsById, mealsById);
    }
  }

  /// Within a day: meal groups first (in eating order), then an Ungrouped
  /// section — but only when the day actually has meals; a day without meals
  /// stays a flat list exactly as before.
  void _writeDayRecords(StringBuffer buffer, List<CalorieRecord> records,
      Map<String, Product> productsById, Map<String, Meal> mealsById) {
    final byMeal = <String, List<CalorieRecord>>{};
    final ungrouped = <CalorieRecord>[];
    for (final record in records) {
      final meal = mealsById[record.mealId];
      if (meal == null) {
        ungrouped.add(record);
      } else {
        byMeal.putIfAbsent(meal.id!, () => []).add(record);
      }
    }

    if (byMeal.isEmpty) {
      for (final record in records) {
        buffer.writeln(_recordLine(record, productsById));
      }
      return;
    }

    for (final entry in byMeal.entries) {
      final meal = mealsById[entry.key]!;
      buffer.writeln(_mealHeader(meal, entry.value));
      for (final record in entry.value) {
        buffer.writeln(_recordLine(record, productsById));
      }
      final notes = meal.notes?.trim() ?? '';
      if (notes.isNotEmpty) {
        buffer.writeln('Notes: $notes');
      }
    }

    if (ungrouped.isNotEmpty) {
      buffer.writeln('### Ungrouped');
      for (final record in ungrouped) {
        buffer.writeln(_recordLine(record, productsById));
      }
    }
  }

  String _mealHeader(Meal meal, List<CalorieRecord> records) {
    final parts = <String>[
      _total(records),
      ..._costSumsParts(records),
      if (meal.cookingMinutes != null) 'cook ${meal.cookingMinutes} min',
      if (meal.tasteRating != null) 'taste ${meal.tasteRating}/5',
      if (meal.satietyRating != null) 'satiety ${meal.satietyRating}/5',
    ];
    return '### Meal: ${meal.title} — ${parts.join(' · ')}';
  }

  void _writePlanned(StringBuffer buffer, List<CalorieRecord> planned,
      Map<String, Product> productsById) {
    if (planned.isEmpty) {
      return;
    }
    buffer
      ..writeln()
      ..writeln('## Planned (not eaten yet)');
    for (final record in planned) {
      buffer.writeln(
          '${_recordLine(record, productsById)} (added ${_date(record.createdAt)})');
    }
  }

  void _writeProducts(
      StringBuffer buffer, List<Product> products, DateTime now) {
    if (products.isEmpty) {
      return;
    }
    final sorted = List<Product>.from(products)
      ..sort((a, b) => b.usesCount.compareTo(a.usesCount));
    buffer
      ..writeln()
      ..writeln('## Products (what this user usually eats, per 100g)');
    for (final product in sorted) {
      final priceUpdatedAt = product.priceUpdatedAt;
      final isStale = product.pricePerPackage != null &&
          priceUpdatedAt != null &&
          now.difference(priceUpdatedAt) > stalePriceAfter;
      final parts = <String>[
        if (product.caloriesPer100g != null)
          '${_num(product.caloriesPer100g!)} kcal',
        if (product.hasFullMacros)
          '(P ${_num(product.proteinsPer100g!)} / F ${_num(product.fatsPer100g!)} / C ${_num(product.carbsPer100g!)})',
        if (product.hasPackageWeight)
          'pack ${_num(product.packageWeightGrams!)}g',
        if (product.pricePerPackage != null)
          'pack price ${_money(product.pricePerPackage!)}${product.priceCurrency == null ? '' : ' ${product.priceCurrency}'}'
              '${isStale ? ' (stale, from ${_date(priceUpdatedAt)})' : ''}',
        if (product.usesCount > 0) 'used ${product.usesCount}×',
      ];
      buffer.writeln(
          '- ${product.title}${parts.isEmpty ? '' : ' — ${parts.join(' · ')}'}');
    }
  }

  String _recordLine(
      CalorieRecord record, Map<String, Product> productsById) {
    final title = _title(record, productsById);
    final weight =
        record.weightGrams == null ? '' : ' ${_num(record.weightGrams!)}g';
    final cost = record.costValue == null
        ? ''
        : ' · ${_money(record.costValue!)}${record.costCurrency == null ? '' : ' ${record.costCurrency}'}';
    return '- $title$weight — ${_num(record.value)} kcal${_macros(record)}$cost';
  }

  /// Per-currency sums; "≥" marks a partial sum (some records lack cost).
  /// Returns [] when no record has a cost, one 'cost …' fragment otherwise.
  List<String> _costSumsParts(List<CalorieRecord> records) {
    final sums = <String, double>{};
    bool missing = false;
    for (final record in records) {
      if (record.costValue == null) {
        missing = true;
      } else {
        final currency = record.costCurrency ?? '?';
        sums[currency] = (sums[currency] ?? 0) + record.costValue!;
      }
    }
    if (sums.isEmpty) {
      return const [];
    }
    final parts = sums.entries
        .map((entry) => '${_money(entry.value)} ${entry.key}')
        .join(' + ');
    return ['cost ${missing ? '≥ ' : ''}$parts'];
  }

  String _costSums(List<CalorieRecord> records) {
    final parts = _costSumsParts(records);
    return parts.isEmpty ? '' : ' · ${parts.single}';
  }

  Set<String> _currenciesIn(
      List<CalorieRecord> records, List<Product> products) {
    return <String>{
      for (final record in records)
        if (record.costCurrency != null && record.costValue != null)
          record.costCurrency!,
      for (final product in products)
        if (product.priceCurrency != null && product.pricePerPackage != null)
          product.priceCurrency!,
    };
  }

  String _title(CalorieRecord record, Map<String, Product> productsById) {
    final description = record.description?.trim() ?? '';
    if (description.isNotEmpty) {
      return description;
    }
    final product = productsById[record.productId];
    if (product != null) {
      return product.title;
    }
    return '(no description)';
  }

  String _total(List<CalorieRecord> records) {
    final total = records.fold<double>(0, (sum, r) => sum + r.value);
    return '${_num(total)} kcal';
  }

  /// Sums only what is present; a day with no macro data gets no parentheses.
  String _macroSums(List<CalorieRecord> records) {
    double protein = 0, fat = 0, carbs = 0;
    bool any = false;
    for (final record in records) {
      if (record.proteinGrams != null ||
          record.fatGrams != null ||
          record.carbGrams != null) {
        any = true;
        protein += record.proteinGrams ?? 0;
        fat += record.fatGrams ?? 0;
        carbs += record.carbGrams ?? 0;
      }
    }
    if (!any) {
      return '';
    }
    return ' (P ${_num(protein)}g / F ${_num(fat)}g / C ${_num(carbs)}g)';
  }

  String _macros(CalorieRecord record) {
    if (record.proteinGrams == null &&
        record.fatGrams == null &&
        record.carbGrams == null) {
      return '';
    }
    String part(double? grams) => grams == null ? '?' : _num(grams);
    return ' (P ${part(record.proteinGrams)} / F ${part(record.fatGrams)} / C ${part(record.carbGrams)})';
  }

  String _date(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }

  String _money(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.endsWith('.00')
        ? fixed.substring(0, fixed.length - 3)
        : fixed;
  }

  String _num(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.05) {
      return rounded.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
