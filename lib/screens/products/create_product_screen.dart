import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/features/profile/domain/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/products/ui/_edit_product_form.dart';

class CreateProductScreen extends StatefulWidget {
  final ProfileModel profile;

  CreateProductScreen(this.profile);

  @override
  CreateProductScreenState createState() => CreateProductScreenState();
}

class CreateProductScreenState extends State<CreateProductScreen> {
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
        title: Text('Create new product', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
            ),
            onPressed: () {
              if (!_formKey.currentState!.validate()) {
                return;
              }

              BlocProvider.of<HomeBloc>(context).add(CreateProductEvent(
                title: titleController.text,
                description: descriptionController.text.length > 0 ? descriptionController.text : null,
                barcode: barcodeController.text.length == 0 ? null : barcodeController.text,
                caloriesPer100g: calorieContentController.text.length > 0 ? double.parse(calorieContentController.text) : null,
                proteinsPer100g: proteinsController.text.length > 0 ? double.parse(proteinsController.text) : null,
                fatsPer100g: fatsController.text.length > 0 ? double.parse(fatsController.text) : null,
                carbsPer100g: carbohydratesController.text.length > 0 ? double.parse(carbohydratesController.text) : null,
              ));

              Navigator.of(context).pop();
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
