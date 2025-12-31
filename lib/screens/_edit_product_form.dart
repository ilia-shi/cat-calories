import 'package:cat_calories/utils/number_validator.dart';
import 'package:flutter/material.dart';

class EditProductForm extends StatelessWidget {

  final Key formKey;

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController barcodeController;
  final TextEditingController calorieContentController;
  final TextEditingController proteinsController;
  final TextEditingController fatsController;
  final TextEditingController carbohydratesController;

  EditProductForm({
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.barcodeController,
    required this.calorieContentController,
    required this.proteinsController,
    required this.fatsController,
    required this.carbohydratesController,
  });

  @override
  Widget build(BuildContext context) {


    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Wrap(
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Title',
              ),
              textCapitalization: TextCapitalization.sentences,
              controller: titleController,
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter title';
                }

                return null;
              },
            ),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
              textCapitalization: TextCapitalization.sentences,
              controller: descriptionController,
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Barcode',
              ),
              textCapitalization: TextCapitalization.sentences,
              controller: barcodeController,
              validator: (String? value) {
                if (value != null && value.isNotEmpty && !NumberValidator.isInteger(value)) {
                  return 'Please enter valid barcode';
                }

                return null;
              },
            ),
            Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 24)),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Calorie content',
              ),
              textCapitalization: TextCapitalization.sentences,
              controller: calorieContentController,
              validator: (String? value) {

                if (value != null && value.isNotEmpty && !NumberValidator.isNumeric(value)) {
                  return 'Please enter valid calories value';
                }

                return null;
              },
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Proteins',
              ),
              textCapitalization: TextCapitalization.sentences,
              controller: proteinsController,
              validator: (String? value) {
                if (value != null && value.isNotEmpty && !NumberValidator.isNumeric(value)) {
                  return 'Please enter valid proteins value';
                }

                return null;
              },
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Fats',
              ),
              textCapitalization: TextCapitalization.sentences,
              controller: fatsController,
              validator: (String? value) {
                if (value != null  && value.isNotEmpty && !NumberValidator.isNumeric(value)) {
                  return 'Please enter valid fats value';
                }

                return null;
              },
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Carbohydrates',
              ),
              textCapitalization: TextCapitalization.sentences,
              controller: carbohydratesController,
              validator: (String? value) {
                if (value != null && value.isNotEmpty && !NumberValidator.isNumeric(value)) {
                  return 'Please enter valid carbohydrates value';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}