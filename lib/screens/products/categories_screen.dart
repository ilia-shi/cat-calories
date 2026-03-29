import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories_core/features/products/domain/product_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductCategoriesScreen extends StatelessWidget {
  const ProductCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context),
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, AbstractHomeState>(
        builder: (context, state) {
          if (state is HomeFetchingInProgress) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HomeFetched) {
            final categories = state.productCategories;

            if (categories.isEmpty) {
              return _buildEmptyState(context);
            }

            return ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final reorderedCategories = List<ProductCategory>.from(categories);
                final item = reorderedCategories.removeAt(oldIndex);
                reorderedCategories.insert(newIndex, item);
                context.read<HomeBloc>().add(
                  ProductCategoriesResortEvent(reorderedCategories),
                );
              },
              itemBuilder: (context, index) {
                final category = categories[index];
                final productCount = state.products
                    .where((p) => p.categoryId == category.id)
                    .length;

                return _CategoryListItem(
                  key: Key('category_${category.id}'),
                  category: category,
                  productCount: productCount,
                  onEdit: () => _showEditCategoryDialog(context, category),
                  onDelete: () => _confirmDelete(context, category, productCount),
                );
              },
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create categories to organize your products',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              context.read<HomeBloc>().add(InitializeDefaultCategoriesEvent());
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Create Default Categories'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        onSave: (name, iconName, colorHex) {
          context.read<HomeBloc>().add(CreateProductCategoryEvent(
            name: name,
            iconName: iconName,
            colorHex: colorHex,
          ));
        },
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, ProductCategory category) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        category: category,
        onSave: (name, iconName, colorHex) {
          final updated = category.copyWith(
            name: name,
            iconName: iconName,
            colorHex: colorHex,
          );
          context.read<HomeBloc>().add(UpdateProductCategoryEvent(updated));
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context,
      ProductCategory category,
      int productCount,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          productCount > 0
              ? 'Are you sure you want to delete "${category.name}"?\n\n'
              '$productCount product(s) in this category will become uncategorized.'
              : 'Are you sure you want to delete "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<HomeBloc>().add(DeleteProductCategoryEvent(category));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CategoryListItem extends StatelessWidget {
  final ProductCategory category;
  final int productCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryListItem({
    super.key,
    required this.category,
    required this.productCount,
    required this.onEdit,
    required this.onDelete,
  });

  Color? _parseColor() {
    if (category.colorHex == null) return null;
    try {
      final hex = category.colorHex!.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor() ?? Colors.grey;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.category,
          color: color,
          size: 22,
        ),
      ),
      title: Text(
        category.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '$productCount product${productCount == 1 ? '' : 's'}',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
          ),
          ReorderableDragStartListener(
            index: 0,
            child: const Icon(Icons.drag_handle, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final ProductCategory? category;
  final void Function(String name, String? iconName, String? colorHex) onSave;

  const _CategoryDialog({
    this.category,
    required this.onSave,
  });

  bool get isEditing => category != null;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameController;
  String? _selectedColorHex;

  static const List<String> _predefinedColors = [
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#FF5722', // Deep Orange
    '#795548', // Brown
    '#9E9E9E', // Grey
    '#607D8B', // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColorHex = widget.category?.colorHex ?? _predefinedColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    final cleanHex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Category' : 'Add Category'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Snacks',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Text(
                'Color',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _predefinedColors.map((colorHex) {
                  final color = _parseColor(colorHex);
                  final isSelected = _selectedColorHex == colorHex;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColorHex = colorHex);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 3,
                        )
                            : null,
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a category name'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            widget.onSave(name, null, _selectedColorHex);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}