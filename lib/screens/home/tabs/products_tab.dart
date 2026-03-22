import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/features/calorie_tracking/domain/calorie_item_model.dart';
import 'package:cat_calories/features/products/domain/product_model.dart';
import 'package:cat_calories/features/waking_periods/domain/waking_period_model.dart';
import 'package:cat_calories/features/products/product_repository.dart';
import 'package:cat_calories/screens/products/add_edit_product_screen.dart';
import 'package:cat_calories/screens/products/categories_screen.dart';
import 'package:cat_calories/ui/widgets/error_state_widget.dart';
import 'package:cat_calories/ui/widgets/macro_chips.dart';
import 'package:cat_calories/ui/widgets/product_weight_input_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/products/domain/product_category_model.dart';

/// Enum for product tab display mode
enum ProductDisplayMode {
  list,
  grid,
}

/// Keys for SharedPreferences
class _ProductPrefsKeys {
  static const String sortOrder = 'products_sort_order';
  static const String displayMode = 'products_display_mode';
  static const String selectedCategory = 'products_selected_category';
}

class ProductsTab extends StatefulWidget {
  const ProductsTab({Key? key}) : super(key: key);

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ProductSortOrder _sortOrder = ProductSortOrder.recentlyUsed;
  ProductDisplayMode _displayMode = ProductDisplayMode.list;
  String? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final sortOrderIndex = prefs.getInt(_ProductPrefsKeys.sortOrder);
      if (sortOrderIndex != null &&
          sortOrderIndex < ProductSortOrder.values.length) {
        _sortOrder = ProductSortOrder.values[sortOrderIndex];
      }

      final displayModeIndex = prefs.getInt(_ProductPrefsKeys.displayMode);
      if (displayModeIndex != null &&
          displayModeIndex < ProductDisplayMode.values.length) {
        _displayMode = ProductDisplayMode.values[displayModeIndex];
      }

      _selectedCategoryId = prefs.getString(_ProductPrefsKeys.selectedCategory);
    } catch (e) {
      debugPrint('Failed to load product preferences: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_ProductPrefsKeys.sortOrder, _sortOrder.index);
      await prefs.setInt(_ProductPrefsKeys.displayMode, _displayMode.index);
      if (_selectedCategoryId != null) {
        await prefs.setString(
            _ProductPrefsKeys.selectedCategory, _selectedCategoryId!);
      } else {
        await prefs.remove(_ProductPrefsKeys.selectedCategory);
      }
    } catch (e) {
      debugPrint('Failed to save product preferences: $e');
    }
  }

  void _setSortOrder(ProductSortOrder sortOrder) {
    setState(() => _sortOrder = sortOrder);
    _savePreferences();
  }

  void _setDisplayMode(ProductDisplayMode displayMode) {
    setState(() => _displayMode = displayMode);
    _savePreferences();
  }

  void _setSelectedCategory(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _savePreferences();
  }

  List<ProductModel> _filterAndSortProducts(
      List<ProductModel> products,
      List<ProductCategoryModel> categories,
      ) {
    // Filter by search query
    var filtered = products.where((product) {
      if (_searchQuery.isEmpty) return true;
      return product.title.toLowerCase().contains(_searchQuery) ||
          (product.description?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    // Filter by category
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((product) => product.categoryId == _selectedCategoryId)
          .toList();
    }

    // Sort products
    switch (_sortOrder) {
      case ProductSortOrder.manual:
        filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
      case ProductSortOrder.mostUsed:
        filtered.sort((a, b) => b.usesCount.compareTo(a.usesCount));
        break;
      case ProductSortOrder.recentlyUsed:
        filtered.sort((a, b) {
          if (a.lastUsedAt == null && b.lastUsedAt == null) {
            return b.usesCount.compareTo(a.usesCount);
          }
          if (a.lastUsedAt == null) return 1;
          if (b.lastUsedAt == null) return -1;
          return b.lastUsedAt!.compareTo(a.lastUsedAt!);
        });
        break;
      case ProductSortOrder.alphabetical:
        filtered.sort(
                (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return filtered;
  }

  void _showProductSheet(
      BuildContext context,
      ProductModel product,
      WakingPeriodModel wakingPeriod,
      List<CalorieItemModel> calorieItems,
      ) {
    if (!product.hasNutrition) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product has no nutrition information'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductWeightInputSheet(
        product: product,
        onSubmit: (result) {
          Navigator.of(context).pop();
          context.read<HomeBloc>().add(
            EatProductEvent(
              product,
              result.weightGrams,
              wakingPeriod,
              calorieItems,
                  (calorieItem) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${result.weightGrams.toStringAsFixed(0)}g of ${product.title} • '
                          '${result.calories.toStringAsFixed(0)} kcal added',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditProductScreen(),
      ),
    );
  }

  void _navigateToEditProduct(BuildContext context, ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: product),
      ),
    );
  }

  void _navigateToCategories(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductCategoriesScreen(),
      ),
    );
  }

  /// Show bottom sheet with product options (Edit, Eat, Remove)
  void _showProductOptionsSheet(
      BuildContext context,
      ProductModel product,
      WakingPeriodModel? wakingPeriod,
      List<CalorieItemModel> calorieItems,
      ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasWakingPeriod = wakingPeriod != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Product title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              // Edit option
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _navigateToEditProduct(context, product);
                },
              ),
              // Eat option
              ListTile(
                leading: Icon(
                  Icons.restaurant,
                  color: hasWakingPeriod ? Colors.green : Colors.grey,
                ),
                title: Text(
                  'Eat',
                  style: TextStyle(
                    color: hasWakingPeriod ? null : Colors.grey,
                  ),
                ),
                subtitle: !hasWakingPeriod
                    ? const Text(
                  'No active waking period',
                  style: TextStyle(fontSize: 12),
                )
                    : null,
                onTap: hasWakingPeriod
                    ? () {
                  Navigator.of(bottomSheetContext).pop();
                  _showProductSheet(
                    context,
                    product,
                    wakingPeriod,
                    calorieItems,
                  );
                }
                    : null,
              ),
              // Remove option
              ListTile(
                leading: const Icon(Icons.delete_outlined, color: Colors.red),
                title: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _showDeleteConfirmationDialog(context, product);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Show confirmation dialog before deleting a product
  Future<void> _showDeleteConfirmationDialog(
      BuildContext context,
      ProductModel product,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<HomeBloc>().add(DeleteProductEvent(product));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${product.title}" deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Products'),
        content: RadioGroup<ProductSortOrder>(
          groupValue: _sortOrder,
          onChanged: (value) {
            if (value != null) {
              _setSortOrder(value);
              Navigator.of(context).pop();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ProductSortOrder.values.map((sortOrder) {
              return RadioListTile<ProductSortOrder>(
                title: Text(_getSortOrderLabel(sortOrder)),
                value: sortOrder,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getSortOrderLabel(ProductSortOrder sortOrder) {
    switch (sortOrder) {
      case ProductSortOrder.manual:
        return 'Manual';
      case ProductSortOrder.mostUsed:
        return 'Most Used';
      case ProductSortOrder.recentlyUsed:
        return 'Recently Used';
      case ProductSortOrder.alphabetical:
        return 'Alphabetical';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocBuilder<HomeBloc, AbstractHomeState>(
      builder: (context, state) {
        if (state is HomeFetchingInProgress) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is HomeError) {
          return ErrorStateWidget(
            message: state.message,
            technicalDetails: state.technicalDetails,
            onRetry: state.canRetry
                ? () => context.read<HomeBloc>().add(
              HomeErrorDismissedEvent(retry: true),
            )
                : null,
            onDismiss: state.previousState != null
                ? () => context.read<HomeBloc>().add(
              HomeErrorDismissedEvent(retry: false),
            )
                : null,
          );
        }

        if (state is HomeFetched) {
          final filteredProducts = _filterAndSortProducts(
            state.products,
            state.productCategories,
          );

          return Column(
            children: [
              _buildSearchBar(context),
              _buildCategoryFilter(context, state),
              _buildToolbar(context, state, filteredProducts.length),
              Expanded(
                child: filteredProducts.isEmpty
                    ? _buildEmptyState(context)
                    : _buildProductsList(context, state, filteredProducts),
              ),
            ],
          );
        }

        return const Center(child: Text('Something went wrong'));
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, HomeFetched state) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _CategoryChip(
            label: 'All',
            isSelected: _selectedCategoryId == null,
            onTap: () => _setSelectedCategory(null),
            isDarkMode: isDarkMode,
          ),
          ...state.productCategories.map((category) {
            return _CategoryChip(
              label: category.name,
              isSelected: _selectedCategoryId == category.id,
              onTap: () => _setSelectedCategory(category.id),
              isDarkMode: isDarkMode,
              colorHex: category.colorHex,
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              avatar: const Icon(Icons.settings, size: 18),
              label: const Text('Manage'),
              onPressed: () => _navigateToCategories(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
      BuildContext context, HomeFetched state, int productCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            '$productCount products',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.sort, size: 22),
            onPressed: () => _showSortDialog(context),
            tooltip: 'Sort',
          ),
          IconButton(
            icon: Icon(
              _displayMode == ProductDisplayMode.list
                  ? Icons.grid_view
                  : Icons.list,
              size: 22,
            ),
            onPressed: () {
              _setDisplayMode(
                _displayMode == ProductDisplayMode.list
                    ? ProductDisplayMode.grid
                    : ProductDisplayMode.list,
              );
            },
            tooltip: 'Toggle view',
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            onPressed: () => _navigateToAddProduct(context),
            tooltip: 'Add product',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No products found'
                : 'No products yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Add your first product to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddProduct(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsList(
      BuildContext context,
      HomeFetched state,
      List<ProductModel> products,
      ) {
    // Check if there's an active waking period
    final wakingPeriod = state.currentWakingPeriod;
    final hasWakingPeriod = wakingPeriod != null;

    if (_displayMode == ProductDisplayMode.grid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.95,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final category = state.getCategoryById(product.categoryId);
          return _ProductGridItem(
            product: product,
            category: category,
            onTap: hasWakingPeriod
                ? () => _showProductSheet(
              context,
              product,
              wakingPeriod,
              state.periodCalorieItems,
            )
                : null,
            onLongPress: () => _showProductOptionsSheet(
              context,
              product,
              wakingPeriod,
              state.periodCalorieItems,
            ),
            onEdit: () => _navigateToEditProduct(context, product),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final category = state.getCategoryById(product.categoryId);
        return _ProductListItem(
          product: product,
          category: category,
          onTap: hasWakingPeriod
              ? () => _showProductSheet(
            context,
            product,
            wakingPeriod,
            state.periodCalorieItems,
          )
              : null,
          onLongPress: () => _showProductOptionsSheet(
            context,
            product,
            wakingPeriod,
            state.periodCalorieItems,
          ),
          onEdit: () => _navigateToEditProduct(context, product),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDarkMode;
  final String? colorHex;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDarkMode,
    this.colorHex,
  });

  Color? _parseColor() {
    if (colorHex == null) return null;
    try {
      final hex = colorHex!.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor();
    final chipColor = isSelected
        ? (color ?? Theme.of(context).primaryColor)
        : (isDarkMode ? Colors.grey[800] : Colors.grey[200]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: chipColor,
        selectedColor: color ?? Theme.of(context).primaryColor,
        checkmarkColor: Colors.white,
        showCheckmark: false,
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final ProductModel product;
  final ProductCategoryModel? category;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;

  const _ProductListItem({
    required this.product,
    this.category,
    this.onTap,
    required this.onLongPress,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.restaurant,
          color: Colors.orange[700],
        ),
      ),
      title: Text(
        product.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.hasNutrition) ...[
            const SizedBox(height: 4),
            MacrosRow(
              calories: product.caloriesPer100g,
              protein: product.proteinsPer100g,
              fat: product.fatsPer100g,
              carbs: product.carbsPer100g,
              compact: true,
            ),
          ],
          if (category != null)
            Text(
              category!.name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (product.usesCount > 0)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${product.usesCount}×',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          ),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: true,
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  final ProductModel product;
  final ProductCategoryModel? category;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;

  const _ProductGridItem({
    required this.product,
    this.category,
    this.onTap,
    required this.onLongPress,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: Colors.orange[700],
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (product.hasNutrition) ...[
                Text(
                  '${product.caloriesPer100g?.toStringAsFixed(0) ?? '-'} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                MacrosInline(
                  protein: product.proteinsPer100g,
                  fat: product.fatsPer100g,
                  carbs: product.carbsPer100g,
                ),
              ],
              if (product.usesCount > 0)
                Text(
                  '${product.usesCount} uses',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}