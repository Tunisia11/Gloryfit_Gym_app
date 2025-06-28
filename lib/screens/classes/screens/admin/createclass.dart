import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/classes/classes_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';

import 'package:gloryfit_version_3/models/classes/class_model.dart';
import 'package:gloryfit_version_3/models/user_model.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _priceController = TextEditingController();

  ClassPriceType _priceType = ClassPriceType.free;
  List<int> _selectedDays = [];
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final userState = context.read<UserCubit>().state;
      if (userState is UserLoaded) {
        context.read<ClassCubit>().createClass(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              coverImageUrl: _imageUrlController.text.trim(),
              trainer: userState.user,
              pricing: ClassPricing(
                type: _priceType,
                amount: double.tryParse(_priceController.text) ?? 0.0,
              ),
              schedule: ClassSchedule(
                startDate: DateTime.now(),
                endDate: DateTime.now().add(const Duration(days: 30)), // Example
                daysOfWeek: _selectedDays,
                timeOfDay: _selectedTime.format(context),
              ),
            );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Class'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Class Details'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Class Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Cover Image URL'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an image URL' : null,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Pricing'),
              _buildPricingTypeSelector(),
              if (_priceType != ClassPriceType.free) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price Amount (\$)'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a price' : null,
                ),
              ],
              const SizedBox(height: 32),
              _buildSectionTitle('Schedule'),
              _buildDaySelector(),
              const SizedBox(height: 16),
              _buildTimePicker(context),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Create Class'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
  
  Widget _buildPricingTypeSelector() {
    return DropdownButtonFormField<ClassPriceType>(
      value: _priceType,
      items: ClassPriceType.values.map((type) {
        return DropdownMenuItem(value: type, child: Text(type.name));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _priceType = value;
          });
        }
      },
      decoration: const InputDecoration(labelText: 'Pricing Model'),
    );
  }

  Widget _buildDaySelector() {
    return Wrap(
      spacing: 8.0,
      children: List.generate(7, (index) {
        final day = index + 1;
        final isSelected = _selectedDays.contains(day);
        return FilterChip(
          label: Text(_dayToString(day)),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(day);
              } else {
                _selectedDays.remove(day);
              }
            });
          },
        );
      }),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return ListTile(
      title: const Text('Class Time'),
      subtitle: Text(_selectedTime.format(context)),
      trailing: const Icon(Icons.edit),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (time != null) {
          setState(() {
            _selectedTime = time;
          });
        }
      },
    );
  }

  String _dayToString(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }
}
