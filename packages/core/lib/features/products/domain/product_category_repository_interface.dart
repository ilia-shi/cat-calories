import 'package:cat_calories_core/features/products/domain/product_category.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';

abstract interface class ProductCategoryRepositoryInterface {
  Future<List<ProductCategory>> fetchByProfile(Profile profile);
  Future<ProductCategory?> find(String id);
  Future<ProductCategory> insert(ProductCategory category);
  Future<ProductCategory> update(ProductCategory category);
  Future<int> delete(ProductCategory category);
  Future<void> resort(List<ProductCategory> categories);
  Future<int> getProductCount(ProductCategory category);
  Future<void> createDefaultCategoriesIfNeeded(Profile profile);
}
