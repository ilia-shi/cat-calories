import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';

import './calorie_record.dart';

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

  String format({
    required Profile profile,
    required List<CalorieRecord> records,
    List<Product> products = const [],
    String? preamble,
  }) {
    final productsById = <String, Product>{
      for (final product in products)
        if (product.id != null) product.id!: product,
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
    buffer
      ..writeln()
      ..writeln(preamble ?? defaultPreamble);

    _writeDays(buffer, eaten, productsById);
    _writePlanned(buffer, planned, productsById);
    _writeProducts(buffer, products);

    return buffer.toString();
  }

  void _writeDays(StringBuffer buffer, List<CalorieRecord> eaten,
      Map<String, Product> productsById) {
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
            '## ${_date(entry.key)} — total ${_total(records)}${_macroSums(records)}');
      for (final record in records) {
        buffer.writeln(_recordLine(record, productsById));
      }
    }
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

  void _writeProducts(StringBuffer buffer, List<Product> products) {
    if (products.isEmpty) {
      return;
    }
    final sorted = List<Product>.from(products)
      ..sort((a, b) => b.usesCount.compareTo(a.usesCount));
    buffer
      ..writeln()
      ..writeln('## Products (what this user usually eats, per 100g)');
    for (final product in sorted) {
      final parts = <String>[
        if (product.caloriesPer100g != null)
          '${_num(product.caloriesPer100g!)} kcal',
        if (product.hasFullMacros)
          '(P ${_num(product.proteinsPer100g!)} / F ${_num(product.fatsPer100g!)} / C ${_num(product.carbsPer100g!)})',
        if (product.hasPackageWeight)
          'pack ${_num(product.packageWeightGrams!)}g',
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
    return '- $title$weight — ${_num(record.value)} kcal${_macros(record)}';
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

  String _num(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.05) {
      return rounded.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
