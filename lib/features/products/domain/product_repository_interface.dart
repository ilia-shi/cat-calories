import 'package:cat_calories/features/products/domain/product_model.dart';
import 'package:cat_calories/features/profile/domain/profile_model.dart';

/// Enum for product sorting options
enum ProductSortOrder {
  /// Sort by manual sort order
  manual,
  /// Sort by most used (uses_count descending)
  mostUsed,
  /// Sort by most recently used
  recentlyUsed,
  /// Sort alphabetically by title
  alphabetical,
}

abstract interface class ProductRepositoryInterface {
  Future<List<ProductModel>> fetchAll();
  Future<List<ProductModel>> fetchByProfile(
      ProfileModel profile, {
        ProductSortOrder sortOrder,
        String? categoryId,
        String? searchQuery,
        int? limit,
      });
  Future<List<ProductModel>> fetchByCategory(
      ProfileModel profile,
      String categoryId, {
        ProductSortOrder sortOrder,
      });
  Future<List<ProductModel>> fetchUncategorized(
      ProfileModel profile, {
        ProductSortOrder sortOrder,
      });
  Future<List<ProductModel>> search(
      ProfileModel profile,
      String query, {
        int limit,
      });
  Future<List<ProductModel>> fetchRecentlyUsed(
      ProfileModel profile, {
        int limit,
      });
  Future<List<ProductModel>> fetchMostUsed(
      ProfileModel profile, {
        int limit,
      });
  Future<ProductModel?> find(String id);
  Future<ProductModel?> findByBarcode(ProfileModel profile, String barcode);
  Future<ProductModel> insert(ProductModel product);
  Future<int> delete(ProductModel product);
  Future<ProductModel> update(ProductModel product);
  Future<ProductModel> recordUsage(ProductModel product);
  Future<void> resort(List<ProductModel> products);
  Future<void> offsetSortOrder();
  Future<Map<String?, int>> getCountByCategory(ProfileModel profile);
}
