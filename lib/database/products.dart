import 'package:cat_calories/models/product/product.dart';
import 'package:cat_calories/models/product/products_database_fruits.dart';
import 'package:cat_calories/models/product/products_database_vegetables.dart';
import 'package:cat_calories/models/product/products_database_other.dart';

class Products {
  static final Products _instance = Products._internal();
  factory Products() => _instance;
  Products._internal();

  late final List<Product> _allProducts = _buildProductsList();
  late final Map<String, Product> _idIndex = _buildIdIndex();
  late final Map<String, List<Product>> _childrenIndex = _buildChildrenIndex();
  late final Map<ProductCategory, List<Product>> _categoryIndex = _buildCategoryIndex();

  List<Product> _buildProductsList() {
    return [
      ...fruitsData,
      ...fruitVariantsData,
      ...vegetablesData,
      ...vegetableVariantsData,
      // ...grainsData,
      // ...grainVariantsData,
      // ...dairyData,
      // ...dairyVariantsData,
      ...fishData,
      ...fishVariantsData,
      ...legumesData,
      ...legumeVariantsData,
      ...nutsData,
      ...nutVariantsData,
      ...eggsData,
      ...eggVariantsData,
      ...oilsData,
      ...bakeryData,
      ...bakeryVariantsData,
    ];
  }

  Map<String, Product> _buildIdIndex() {
    final index = <String, Product>{};
    for (final product in _allProducts) {
      index[product.id] = product;
    }
    return index;
  }

  /// Build children index for hierarchy navigation
  Map<String, List<Product>> _buildChildrenIndex() {
    final index = <String, List<Product>>{};
    for (final product in _allProducts) {
      if (product.parentId != null) {
        index.putIfAbsent(product.parentId!, () => []).add(product);
      }
    }
    return index;
  }

  /// Build category index for fast category filtering
  Map<ProductCategory, List<Product>> _buildCategoryIndex() {
    final index = <ProductCategory, List<Product>>{};
    for (final category in ProductCategory.values) {
      index[category] = [];
    }
    for (final product in _allProducts) {
      index[product.category]!.add(product);
    }
    return index;
  }

  // ============================================================
  // PUBLIC API
  // ============================================================

  /// Get all products in the database
  List<Product> get all => List.unmodifiable(_allProducts);

  /// Get total number of products
  int get count => _allProducts.length;

  /// Find a product by its unique ID
  /// Returns null if not found
  Product? findById(String id) => _idIndex[id];

  /// Find a product by ID, throws if not found
  Product getById(String id) {
    final product = findById(id);
    if (product == null) {
      throw ArgumentError('Product not found: $id');
    }
    return product;
  }

  /// Search products by name (case-insensitive)
  /// Returns products where title contains the query
  /// Optionally filter by category
  List<Product> search(
      String query, {
        ProductCategory? category,
        bool includeVariantsOnly = false,
        bool includeTopLevelOnly = false,
        int? limit,
      }) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    var results = _allProducts.where((p) {
      // Check name match
      if (!p.title.toLowerCase().contains(lowerQuery)) {
        // Also check tags
        if (!p.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
          return false;
        }
      }

      // Apply filters
      if (category != null && p.category != category) return false;
      if (includeVariantsOnly && !p.isVariant) return false;
      if (includeTopLevelOnly && !p.isTopLevel) return false;

      return true;
    });

    // Sort by relevance (exact title match first, then by title length)
    final resultsList = results.toList()
      ..sort((a, b) {
        final aExact = a.title.toLowerCase() == lowerQuery;
        final bExact = b.title.toLowerCase() == lowerQuery;
        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;

        final aStartsWith = a.title.toLowerCase().startsWith(lowerQuery);
        final bStartsWith = b.title.toLowerCase().startsWith(lowerQuery);
        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;

        // Top-level products before variants
        if (a.isTopLevel && !b.isTopLevel) return -1;
        if (!a.isTopLevel && b.isTopLevel) return 1;

        return a.title.length.compareTo(b.title.length);
      });

    if (limit != null && resultsList.length > limit) {
      return resultsList.sublist(0, limit);
    }
    return resultsList;
  }

  /// Get all products in a category
  List<Product> getByCategory(ProductCategory category) {
    return List.unmodifiable(_categoryIndex[category] ?? []);
  }

  /// Get all top-level products (no parent) in a category
  List<Product> getTopLevelByCategory(ProductCategory category) {
    return getByCategory(category).where((p) => p.isTopLevel).toList();
  }

  /// Get all child variants of a product
  List<Product> getVariants(String parentId) {
    return List.unmodifiable(_childrenIndex[parentId] ?? []);
  }

  /// Check if a product has variants
  bool hasVariants(String productId) {
    return _childrenIndex.containsKey(productId) &&
        _childrenIndex[productId]!.isNotEmpty;
  }

  /// Get the parent product of a variant
  Product? getParent(String productId) {
    final product = findById(productId);
    if (product == null || product.parentId == null) return null;
    return findById(product.parentId!);
  }

  /// Get the full hierarchy path for a product (from root to product)
  List<Product> getHierarchyPath(String productId) {
    final path = <Product>[];
    var current = findById(productId);

    while (current != null) {
      path.insert(0, current);
      current = current.parentId != null ? findById(current.parentId!) : null;
    }

    return path;
  }

  /// Get all available categories
  List<ProductCategory> get categories => ProductCategory.values;

  /// Get categories that have products
  List<ProductCategory> get nonEmptyCategories {
    return ProductCategory.values
        .where((c) => (_categoryIndex[c]?.isNotEmpty ?? false))
        .toList();
  }

  /// Get product count per category
  Map<ProductCategory, int> get categoryCounts {
    return _categoryIndex.map((key, value) => MapEntry(key, value.length));
  }

  /// Get products with specific tags
  List<Product> getByTag(String tag) {
    final lowerTag = tag.toLowerCase();
    return _allProducts
        .where((p) => p.tags.any((t) => t.toLowerCase() == lowerTag))
        .toList();
  }

  /// Get products by multiple tags (AND logic - must have all tags)
  List<Product> getByTags(List<String> tags) {
    if (tags.isEmpty) return [];

    final lowerTags = tags.map((t) => t.toLowerCase()).toSet();
    return _allProducts
        .where((p) {
      final productTags = p.tags.map((t) => t.toLowerCase()).toSet();
      return lowerTags.every((tag) => productTags.contains(tag));
    })
        .toList();
  }

  /// Get products by any of the tags (OR logic - must have at least one tag)
  List<Product> getByAnyTag(List<String> tags) {
    if (tags.isEmpty) return [];

    final lowerTags = tags.map((t) => t.toLowerCase()).toSet();
    return _allProducts
        .where((p) {
      final productTags = p.tags.map((t) => t.toLowerCase()).toSet();
      return lowerTags.any((tag) => productTags.contains(tag));
    })
        .toList();
  }

  /// Get all unique tags in the database
  Set<String> get allTags {
    final tags = <String>{};
    for (final product in _allProducts) {
      tags.addAll(product.tags);
    }
    return tags;
  }

  /// Get products within a calorie range (per 100g)
  List<Product> getByCalorieRange({
    double? minCalories,
    double? maxCalories,
    ProductCategory? category,
  }) {
    return _allProducts.where((p) {
      final avgCalories = p.caloriesPer100g.average;
      if (minCalories != null && avgCalories < minCalories) return false;
      if (maxCalories != null && avgCalories > maxCalories) return false;
      if (category != null && p.category != category) return false;
      return true;
    }).toList();
  }

  /// Get low-calorie products (under 50 kcal/100g)
  List<Product> get lowCalorieProducts =>
      getByCalorieRange(maxCalories: 50);

  /// Get high-protein products (over 15g/100g)
  List<Product> get highProteinProducts =>
      _allProducts.where((p) => p.proteinPer100g.average > 15).toList();

  /// Get low-carb products (under 10g/100g)
  List<Product> get lowCarbProducts =>
      _allProducts.where((p) => p.carbsPer100g.average < 10).toList();

  /// Get high-fiber products (over 5g/100g)
  List<Product> get highFiberProducts =>
      _allProducts.where((p) => (p.fiberPer100g?.average ?? 0) > 5).toList();

  /// Get products sorted by a nutrient (descending)
  List<Product> sortedByProtein({ProductCategory? category, int? limit}) {
    var products = category != null ? getByCategory(category) : all;
    products = products.toList()
      ..sort((a, b) => b.proteinPer100g.average.compareTo(a.proteinPer100g.average));
    if (limit != null) return products.take(limit).toList();
    return products;
  }

  List<Product> sortedByCalories({ProductCategory? category, int? limit, bool ascending = true}) {
    var products = category != null ? getByCategory(category) : all;
    products = products.toList()
      ..sort((a, b) => ascending
          ? a.caloriesPer100g.average.compareTo(b.caloriesPer100g.average)
          : b.caloriesPer100g.average.compareTo(a.caloriesPer100g.average));
    if (limit != null) return products.take(limit).toList();
    return products;
  }

  List<Product> sortedByFiber({ProductCategory? category, int? limit}) {
    var products = category != null ? getByCategory(category) : all;
    products = products.toList()
      ..sort((a, b) => (b.fiberPer100g?.average ?? 0).compareTo(a.fiberPer100g?.average ?? 0));
    if (limit != null) return products.take(limit).toList();
    return products;
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Get database statistics
  ProductsDatabaseStats get stats => ProductsDatabaseStats(
    totalProducts: count,
    topLevelProducts: _allProducts.where((p) => p.isTopLevel).length,
    variants: _allProducts.where((p) => p.isVariant).length,
    categoryCounts: categoryCounts,
    uniqueTags: allTags.length,
  );
}

/// Statistics about the products database
class ProductsDatabaseStats {
  final int totalProducts;
  final int topLevelProducts;
  final int variants;
  final Map<ProductCategory, int> categoryCounts;
  final int uniqueTags;

  const ProductsDatabaseStats({
    required this.totalProducts,
    required this.topLevelProducts,
    required this.variants,
    required this.categoryCounts,
    required this.uniqueTags,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Products Database Statistics:');
    buffer.writeln('  Total products: $totalProducts');
    buffer.writeln('  Top-level products: $topLevelProducts');
    buffer.writeln('  Variants: $variants');
    buffer.writeln('  Unique tags: $uniqueTags');
    buffer.writeln('  By category:');
    for (final entry in categoryCounts.entries) {
      if (entry.value > 0) {
        buffer.writeln('    ${entry.key.displayName}: ${entry.value}');
      }
    }
    return buffer.toString();
  }
}