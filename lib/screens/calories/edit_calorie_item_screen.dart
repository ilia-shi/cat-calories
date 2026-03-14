import 'package:cat_calories/blocs/home/home_bloc.dart';
import 'package:cat_calories/blocs/home/home_event.dart';
import 'package:cat_calories/blocs/home/home_state.dart';
import 'package:cat_calories/models/calorie_item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class EditCalorieItemScreen extends StatefulWidget {
  final CalorieItemModel calorieItem;

  EditCalorieItemScreen(this.calorieItem);

  @override
  EditCalorieItemScreenState createState() =>
      EditCalorieItemScreenState(this.calorieItem);
}

class EditCalorieItemScreenState extends State<EditCalorieItemScreen> {
  // Core fields
  TextEditingController _valueController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  // Nutritional fields
  TextEditingController _weightController = TextEditingController();
  TextEditingController _proteinController = TextEditingController();
  TextEditingController _fatController = TextEditingController();
  TextEditingController _carbController = TextEditingController();

  CalorieItemModel calorieItem;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _showNutritionFields = false;

  EditCalorieItemScreenState(this.calorieItem);

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _valueController.text = calorieItem.value.toString();
    _descriptionController.text =
        (calorieItem.description == null ? '' : calorieItem.description)
            .toString();

    // Initialize nutritional fields
    _weightController.text = calorieItem.weightGrams?.toString() ?? '';
    _proteinController.text = calorieItem.proteinGrams?.toString() ?? '';
    _fatController.text = calorieItem.fatGrams?.toString() ?? '';
    _carbController.text = calorieItem.carbGrams?.toString() ?? '';

    // Show nutrition section if any nutritional data exists
    _showNutritionFields = calorieItem.weightGrams != null ||
        calorieItem.proteinGrams != null ||
        calorieItem.fatGrams != null ||
        calorieItem.carbGrams != null;

    // Initialize date and time from the calorie item
    _selectedDate = calorieItem.createdAt;
    _selectedTime = TimeOfDay.fromDateTime(calorieItem.createdAt);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbController.dispose();

    super.dispose();
  }

  double? _parseNullableDouble(String text) {
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveCalorieItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    calorieItem.value = double.parse(_valueController.text);
    calorieItem.description = _descriptionController.text.length == 0
        ? null
        : _descriptionController.text;

    // Update nutritional data
    calorieItem.weightGrams = _parseNullableDouble(_weightController.text);
    calorieItem.proteinGrams = _parseNullableDouble(_proteinController.text);
    calorieItem.fatGrams = _parseNullableDouble(_fatController.text);
    calorieItem.carbGrams = _parseNullableDouble(_carbController.text);

    // Update the date
    calorieItem.createdAt = _selectedDate;

    // Update eatenAt if it was set
    if (calorieItem.eatenAt != null) {
      calorieItem.eatenAt = _selectedDate;
    }

    BlocProvider.of<HomeBloc>(context)
        .add(CalorieItemListUpdatingEvent(calorieItem, [], () {
      Navigator.of(context).pop();
    }));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Edit calorie item',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            )),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveCalorieItem,
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, AbstractHomeState>(
          builder: (BuildContext context, state) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Calories Value Field
                    TextFormField(
                      controller: _valueController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Calories (kcal)',
                        hintText: 'Enter calorie value',
                        prefixIcon: Icon(Icons.local_fire_department),
                        enabledBorder: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter kcal value';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Description Field
                    TextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What did you eat?',
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                        enabledBorder: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nutritional Information Section
                    _buildNutritionSection(),

                    const SizedBox(height: 32),

                    // Date & Time Section
                    Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date Picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEEE, MMMM d, y')
                                        .format(_selectedDate),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Time Picker
                    InkWell(
                      onTap: () => _selectTime(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('HH:mm').format(_selectedDate),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Date Buttons
                    Text(
                      'Quick Select',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickDateChip('Today', DateTime.now()),
                        _buildQuickDateChip(
                          'Yesterday',
                          DateTime.now().subtract(const Duration(days: 1)),
                        ),
                        _buildQuickDateChip(
                          '2 days ago',
                          DateTime.now().subtract(const Duration(days: 2)),
                        ),
                        _buildQuickDateChip(
                          '3 days ago',
                          DateTime.now().subtract(const Duration(days: 3)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Changing the date will move this entry to the selected day in your history.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }

  Widget _buildNutritionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Toggle
        InkWell(
          onTap: () {
            setState(() {
              _showNutritionFields = !_showNutritionFields;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: Colors.green.shade600,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nutritional Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Optional',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _showNutritionFields ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable Content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildNutritionFields(),
          crossFadeState: _showNutritionFields
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildNutritionFields() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        children: [
          // Weight Field
          _buildNutritionField(
            controller: _weightController,
            label: 'Weight',
            hint: 'e.g., 150',
            suffix: 'g',
            icon: Icons.scale,
          ),

          const SizedBox(height: 16),

          // Macros Row 1: Protein & Fat
          Row(
            children: [
              Expanded(
                child: _buildNutritionField(
                  controller: _proteinController,
                  label: 'Protein',
                  hint: 'e.g., 25',
                  suffix: 'g',
                  icon: Icons.egg_alt_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNutritionField(
                  controller: _fatController,
                  label: 'Fat',
                  hint: 'e.g., 10',
                  suffix: 'g',
                  icon: Icons.water_drop_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Carbs Field
          Row(
            children: [
              Expanded(
                child: _buildNutritionField(
                  controller: _carbController,
                  label: 'Carbs',
                  hint: 'e.g., 30',
                  suffix: 'g',
                  icon: Icons.bakery_dining_outlined,
                ),
              ),
              const Expanded(child: SizedBox()), // Spacer for alignment
            ],
          ),

          const SizedBox(height: 16),

          // Nutrition Summary
          if (_hasAnyNutritionData()) _buildNutritionSummary(),
        ],
      ),
    );
  }

  Widget _buildNutritionField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green.shade400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
      validator: (String? value) {
        if (value != null && value.isNotEmpty) {
          if (double.tryParse(value) == null) {
            return 'Invalid number';
          }
          if (double.parse(value) < 0) {
            return 'Must be positive';
          }
        }
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  bool _hasAnyNutritionData() {
    return _weightController.text.isNotEmpty ||
        _proteinController.text.isNotEmpty ||
        _fatController.text.isNotEmpty ||
        _carbController.text.isNotEmpty;
  }

  Widget _buildNutritionSummary() {
    final protein = _parseNullableDouble(_proteinController.text) ?? 0;
    final fat = _parseNullableDouble(_fatController.text) ?? 0;
    final carbs = _parseNullableDouble(_carbController.text) ?? 0;

    // Calculate calories from macros (4 cal/g protein, 9 cal/g fat, 4 cal/g carbs)
    final calculatedCalories = (protein * 4) + (fat * 9) + (carbs * 4);
    final enteredCalories = double.tryParse(_valueController.text) ?? 0;

    final hasAllMacros = _proteinController.text.isNotEmpty &&
        _fatController.text.isNotEmpty &&
        _carbController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_outlined,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'Macro Summary',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroChip('P', protein, Colors.blue),
              _buildMacroChip('F', fat, Colors.orange),
              _buildMacroChip('C', carbs, Colors.purple),
            ],
          ),
          if (hasAllMacros && calculatedCalories > 0) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calculated from macros:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${calculatedCalories.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            if ((calculatedCalories - enteredCalories).abs() > 10 &&
                enteredCalories > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Differs from entered calories by ${(calculatedCalories - enteredCalories).abs().toStringAsFixed(0)} kcal',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${value.toStringAsFixed(1)}g',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateChip(String label, DateTime date) {
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
          : Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).primaryColor
            : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).primaryColor
            : Colors.grey.shade300,
      ),
      onPressed: () {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            _selectedTime.hour,
            _selectedTime.minute,
          );
        });
      },
    );
  }
}