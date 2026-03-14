final class NutrientRange {
  final double min;
  final double max;

  const NutrientRange({required this.min, required this.max});

  /// Creates a range with a single value (min == max)
  const NutrientRange.fixed(double value) : min = value, max = value;

  /// Returns the average of min and max
  double get average => (min + max) / 2;

  @override
  String toString() => min == max ? '$min' : '$min-$max';
}

enum ProductCategory {
  vegetables('Vegetables', '🥬'),
  fruits('Fruits', '🍎'),
  grains('Grains & Cereals', '🌾'),
  dairy('Dairy Products', '🥛'),
  meat('Meat & Poultry', '🥩'),
  fish('Fish & Seafood', '🐟'),
  legumes('Legumes & Beans', '🫘'),
  nuts('Nuts & Seeds', '🥜'),
  oils('Oils & Fats', '🫒'),
  beverages('Beverages', '🥤'),
  sweets('Sweets & Desserts', '🍰'),
  condiments('Condiments & Sauces', '🧂'),
  eggs('Eggs', '🥚'),
  bakery('Bakery', '🍞');

  final String displayName;
  final String emoji;

  const ProductCategory(this.displayName, this.emoji);
}

/// Represents a food product with nutritional information
/// Supports hierarchical structure where products can have parent/child relationships
final class Product {
  /// Unique identifier (UUID)
  final String id;

  /// Display name of the product
  final String title;

  /// Optional detailed description
  final String? description;

  /// Product category
  final ProductCategory category;

  /// Parent product ID for hierarchical structure (null if top-level)
  final String? parentId;

  /// Calories per 100g (kcal)
  final NutrientRange caloriesPer100g;

  /// Protein per 100g (grams)
  final NutrientRange proteinPer100g;

  /// Fat per 100g (grams)
  final NutrientRange fatPer100g;

  /// Carbohydrates per 100g (grams)
  final NutrientRange carbsPer100g;

  /// Dietary fiber per 100g (grams)
  final NutrientRange? fiberPer100g;

  /// Sugar per 100g (grams)
  final NutrientRange? sugarPer100g;

  /// Sodium per 100g (mg)
  final double? sodiumPer100g;

  /// Water content per 100g (grams)
  final double? waterPer100g;

  /// Glycemic index (0-100)
  final int? glycemicIndex;

  /// Common serving size in grams
  final double? servingSizeGrams;

  /// Description of common serving (e.g., "1 medium apple")
  final String? servingDescription;

  /// Tags for searching (e.g., "raw", "cooked", "organic")
  final List<String> tags;

  /// Whether this product has child variants
  final bool hasVariants;

  const Product({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.parentId,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbsPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.sodiumPer100g,
    this.waterPer100g,
    this.glycemicIndex,
    this.servingSizeGrams,
    this.servingDescription,
    this.tags = const [],
    this.hasVariants = false,
  });

  /// Check if this is a top-level product (no parent)
  bool get isTopLevel => parentId == null;

  /// Check if this is a variant of another product
  bool get isVariant => parentId != null;

  /// Calculate calories for a given weight in grams
  double caloriesForWeight(double grams) => caloriesPer100g.average * grams / 100;

  /// Calculate protein for a given weight in grams
  double proteinForWeight(double grams) => proteinPer100g.average * grams / 100;

  /// Calculate fat for a given weight in grams
  double fatForWeight(double grams) => fatPer100g.average * grams / 100;

  /// Calculate carbs for a given weight in grams
  double carbsForWeight(double grams) => carbsPer100g.average * grams / 100;

  @override
  String toString() => 'Product($title, ${caloriesPer100g}kcal/100g)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Product && id == other.id;

  @override
  int get hashCode => id.hashCode;
}