import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/product_model.dart';
import 'package:cat_calories/screens/_edit_product_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  EditProductScreen(this.product);

  @override
  _EditProductScreenState createState() => _EditProductScreenState(product);
}

class _EditProductScreenState extends State<EditProductScreen> {
  final ProductModel product;

  _EditProductScreenState(this.product);

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController barcodeController = TextEditingController();
  TextEditingController calorieContentController = TextEditingController();
  TextEditingController proteinsController = TextEditingController();
  TextEditingController fatsController = TextEditingController();
  TextEditingController carbohydratesController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    titleController.text = product.title;
    descriptionController.text = product.description == null ? '' : product.description.toString();
    barcodeController.text = product.barcode == null ? '' : product.barcode.toString();
    calorieContentController.text = product.caloriesPer100g == null ? '' : product.caloriesPer100g.toString();
    proteinsController.text = product.proteinsPer100g == null ? '' : product.proteinsPer100g.toString();
    fatsController.text = product.fatsPer100g == null ? '' : product.fatsPer100g.toString();
    carbohydratesController.text = product.carbsPer100g == null ? '' : product.carbsPer100g.toString();

    super.initState();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    barcodeController.dispose();
    calorieContentController.dispose();
    proteinsController.dispose();
    fatsController.dispose();
    carbohydratesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit product'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
            ),
            onPressed: () {
              if (!_formKey.currentState!.validate()) {
                return;
              }

              product.title = titleController.text;
              product.description = descriptionController.text.length > 0 ? descriptionController.text : null;
              product.barcode = barcodeController.text.length == 0 ? null : (barcodeController.text);
              product.carbsPer100g =
                  calorieContentController.text.length > 0 ? double.parse(calorieContentController.text) : null;
              product.proteinsPer100g = proteinsController.text.length > 0 ? double.parse(proteinsController.text) : null;
              product.fatsPer100g = fatsController.text.length > 0 ? double.parse(fatsController.text) : null;
              product.carbsPer100g = carbohydratesController.text.length > 0 ? double.parse(carbohydratesController.text) : null;

              BlocProvider.of<HomeBloc>(context).add(UpdateProductEvent(product));

              Navigator.of(context).pop();
              // Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: BlocBuilder<HomeBloc, AbstractHomeState>(builder: (BuildContext context, state) {
          return EditProductForm(
            formKey: _formKey,
            titleController: titleController,
            descriptionController: descriptionController,
            barcodeController: barcodeController,
            calorieContentController: calorieContentController,
            proteinsController: proteinsController,
            fatsController: fatsController,
            carbohydratesController: carbohydratesController,
          );
        }),
      ),
    );
  }
}
