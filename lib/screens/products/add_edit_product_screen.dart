import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories_core/features/products/domain/product_category.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({
    Key? key,
    this.product,
  }) : super(key: key);

  bool get isEditing => product != null;

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  late final TextEditingController _carbsController;
  late final TextEditingController _packageWeightController;

  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _titleController = TextEditingController(text: product?.title ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _barcodeController = TextEditingController(
      text: product?.barcode?.toString() ?? '',
    );
    _caloriesController = TextEditingController(
      text: product?.caloriesPer100g?.toString() ?? '',
    );
    _proteinController = TextEditingController(
      text: product?.proteinsPer100g?.toString() ?? '',
    );
    _fatController = TextEditingController(
      text: product?.fatsPer100g?.toString() ?? '',
    );
    _carbsController = TextEditingController(
      text: product?.carbsPer100g?.toString() ?? '',
    );
    _packageWeightController = TextEditingController(
      text: product?.packageWeightGrams?.toString() ?? '',
    );
    _selectedCategoryId = product?.categoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _packageWeightController.dispose();
    super.dispose();
  }

  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  String? _parseBarcode(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    if (widget.isEditing) {
      // Update existing product
      final updatedProduct = widget.product!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        barcode: _parseBarcode(_barcodeController.text),
        caloriesPer100g: _parseDouble(_caloriesController.text.trim()),
        proteinsPer100g: _parseDouble(_proteinController.text.trim()),
        fatsPer100g: _parseDouble(_fatController.text.trim()),
        carbsPer100g: _parseDouble(_carbsController.text.trim()),
        packageWeightGrams: _parseDouble(_packageWeightController.text.trim()),
        categoryId: _selectedCategoryId,
      );

      context.read<HomeBloc>().add(UpdateProductEvent(updatedProduct));
    } else {
      // Create new product
      context.read<HomeBloc>().add(CreateProductEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        barcode: _parseBarcode(_barcodeController.text),
        caloriesPer100g: _parseDouble(_caloriesController.text.trim()),
        proteinsPer100g: _parseDouble(_proteinController.text.trim()),
        fatsPer100g: _parseDouble(_fatController.text.trim()),
        carbsPer100g: _parseDouble(_carbsController.text.trim()),
        packageWeightGrams: _parseDouble(_packageWeightController.text.trim()),
        categoryId: _selectedCategoryId,
      ));
    }

    Navigator.of(context).pop();
  }

  void _confirmDelete() {
    if (widget.product == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${widget.product!.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<HomeBloc>().add(DeleteProductEvent(widget.product!));
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: 'Delete',
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, AbstractHomeState>(
        builder: (context, state) {
          final categories = state is HomeFetched
              ? state.productCategories
              : <ProductCategory>[];

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildCategorySection(categories),
                const SizedBox(height: 24),
                _buildNutritionSection(),
                const SizedBox(height: 24),
                _buildPackageSection(),
                const SizedBox(height: 24),
                _buildBarcodeSection(),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Information', Icons.info_outline),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Product Name *',
            hintText: 'e.g., Tofu',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a product name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'Add any notes about this product',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildCategorySection(List<ProductCategory> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Category', Icons.category_outlined),
        DropdownButtonFormField<String?>(
          value: _selectedCategoryId,
          decoration: const InputDecoration(
            labelText: 'Category (optional)',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('No category'),
            ),
            ...categories.map((category) {
              return DropdownMenuItem<String?>(
                value: category.id.toString(),
                child: Text(category.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() => _selectedCategoryId = value);
          },
        ),
      ],
    );
  }

  Widget _buildNutritionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Nutrition (per 100g)', Icons.restaurant_menu),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _caloriesController,
                decoration: InputDecoration(
                  labelText: 'Calories',
                  hintText: '0',
                  suffixText: 'kcal',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.orange.withOpacity(0.05),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _proteinController,
                decoration: InputDecoration(
                  labelText: 'Protein',
                  hintText: '0',
                  suffixText: 'g',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.red.withOpacity(0.05),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Invalid';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _fatController,
                decoration: InputDecoration(
                  labelText: 'Fat',
                  hintText: '0',
                  suffixText: 'g',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.amber.withOpacity(0.05),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Invalid';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _carbsController,
                decoration: InputDecoration(
                  labelText: 'Carbs',
                  hintText: '0',
                  suffixText: 'g',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.green.withOpacity(0.05),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Invalid';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tip: Enter calories per 100g. When you use this product, '
              'you\'ll enter the weight to calculate actual calories.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPackageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Package Weight (optional)', Icons.inventory_2_outlined),
        TextFormField(
          controller: _packageWeightController,
          decoration: const InputDecoration(
            labelText: 'Package Weight',
            hintText: 'e.g., 250',
            suffixText: 'g',
            border: OutlineInputBorder(),
            helperText: 'Add package weight to enable "Eat entire package" option',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return 'Invalid number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBarcodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Barcode (optional)', Icons.qr_code),
        TextFormField(
          controller: _barcodeController,
          decoration: const InputDecoration(
            labelText: 'Barcode',
            hintText: 'e.g., 4607026602217',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }
}