import 'package:flutter/material.dart';

final class EditPlanForm extends StatelessWidget {
  final Key formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  EditPlanForm({
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
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
            Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 24)),
          ],
        ),
      ),
    );
  }
}
