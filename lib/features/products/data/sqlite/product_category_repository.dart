import 'package:cat_calories/database/database_client.dart';
import 'package:cat_calories_core/features/products/domain/product_category.dart';
import 'package:cat_calories_core/features/products/domain/product_category_repository_interface.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing product categories
class ProductCategoryRepository implements ProductCategoryRepositoryInterface {
  static const String tableName = 'product_categories';
  static const _uuid = Uuid();
  final DatabaseClient _db;

  ProductCategoryRepository(this._db);

  /// Fetch all categories for a given profile
  Future<List<ProductCategory>> fetchByProfile(Profile profile) async {
    final result = await _db.query(
      tableName,
      where: 'profile_id = ?',
      whereArgs: [profile.id],
      orderBy: 'sort_order ASC, name ASC',
    );

    return result.map((e) => ProductCategory.fromJson(e)).toList();
  }

  /// Fetch a single category by UUID
  Future<ProductCategory?> find(String id) async {
    final result = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ProductCategory.fromJson(result.first);
  }

  /// Insert a new category (generates UUID if not provided)
  Future<ProductCategory> insert(ProductCategory category) async {
    if (category.id == null || category.id!.isEmpty) {
      category.id = _uuid.v4();
    }
    await _db.insert(tableName, category.toJson());
    return category;
  }

  /// Update an existing category
  Future<ProductCategory> update(ProductCategory category) async {
    category.updatedAt = DateTime.now();
    await _db.update(
      tableName,
      category.toJson(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return category;
  }

  /// Delete a category
  Future<int> delete(ProductCategory category) async {
    // First, remove category_id from all products using this category
    await _db.update(
      'products',
      {'category_id': null},
      where: 'category_id = ?',
      whereArgs: [category.id],
    );

    return await _db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Resort categories
  Future<void> resort(List<ProductCategory> categories) async {
    final Batch batch = await _db.batch();

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      batch.update(
        tableName,
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [category.id],
      );
    }

    await batch.commit();
  }

  /// Get the count of products in a category
  Future<int> getProductCount(ProductCategory category) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE category_id = ?',
      [category.id],
    );

    return result.first['count'] as int;
  }

  /// Create default categories for a profile if none exist
  Future<void> createDefaultCategoriesIfNeeded(Profile profile) async {
    final existing = await fetchByProfile(profile);
    if (existing.isNotEmpty) return;

    final defaultCategories = [
      ('Beverages', 'local_drink', '#2196F3'),
      ('Fruits & Vegetables', 'eco', '#4CAF50'),
      ('Dairy', 'egg', '#FFC107'),
      ('Meat & Fish', 'restaurant', '#F44336'),
      ('Grains & Bread', 'bakery_dining', '#795548'),
      ('Snacks', 'cookie', '#FF9800'),
      ('Other', 'category', '#9E9E9E'),
    ];

    for (int i = 0; i < defaultCategories.length; i++) {
      final (name, iconName, colorHex) = defaultCategories[i];
      await insert(ProductCategory(
        id: null,
        name: name,
        iconName: iconName,
        colorHex: colorHex,
        sortOrder: i,
        profileId: profile.id!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }
}