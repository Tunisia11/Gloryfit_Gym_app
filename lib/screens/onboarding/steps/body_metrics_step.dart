import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:intl/intl.dart';

class BodyMetricsStep extends StatefulWidget {
  final UserModel user;
  const BodyMetricsStep({super.key, required this.user});

  @override
  State<BodyMetricsStep> createState() => _BodyMetricsStepState();
}

class _BodyMetricsStepState extends State<BodyMetricsStep> {
  late DateTime _selectedDate;
  late double _selectedHeight;
  late double _selectedWeight;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.user.dateOfBirth ?? DateTime(2000, 1, 1);
    _selectedHeight = widget.user.height ?? 170;
    _selectedWeight = widget.user.weight ?? 70;
  }
  
  String get _age {
    final now = DateTime.now();
    int age = now.year - _selectedDate.year;
    if (now.month < _selectedDate.month || (now.month == _selectedDate.month && now.day < _selectedDate.day)) {
      age--;
    }
    return age.toString();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Color(0xFF101010),
            ),
            dialogBackgroundColor: const Color(0xFF181818),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          const Text(
            "What are your metrics?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          _buildDatePicker(context),
          const SizedBox(height: 24),
          _buildSlider("Height", _selectedHeight, 120, 220, "cm", (val) {
            setState(() => _selectedHeight = val);
          }),
          const SizedBox(height: 24),
          _buildSlider("Weight", _selectedWeight, 40, 150, "kg", (val) {
            setState(() => _selectedWeight = val);
          }),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<UserCubit>().setOnboardingStep(
                      2,
                      dateOfBirth: _selectedDate,
                      height: _selectedHeight,
                      weight: _selectedWeight,
                    );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Age", style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$_age years old",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  DateFormat.yMMMd().format(_selectedDate),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            Text("${value.toStringAsFixed(0)} $unit",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8.0,
            trackShape: const RoundedRectSliderTrackShape(),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade800,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withAlpha(32),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 28.0),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
