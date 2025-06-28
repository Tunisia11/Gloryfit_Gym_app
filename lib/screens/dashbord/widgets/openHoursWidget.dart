// lib/screens/dashbord/widgets/opening_hours_status.dart
import 'package:flutter/material.dart';

class OpeningHoursStatus extends StatelessWidget {
  const OpeningHoursStatus({super.key});

  // --- 🎨 UI CONFIGURATION ---
  static const Color _openColor = Color(0xFF1E8E3E); // Green
  static const Color _closedColor = Color(0xFFD93025); // Red

  // --- ⏰ BUSINESS HOURS CONFIGURATION (24-hour format) ---
  // This schedule remains the same.
  static const Map<int, List<int>> _schedule = {
    DateTime.monday: [6, 22],
    DateTime.tuesday: [6, 22],
    DateTime.wednesday: [6, 22],
    DateTime.thursday: [6, 22],
    DateTime.friday: [6, 22],
    DateTime.saturday: [8, 20],
  };

  /// Checks if the business is currently open based on the schedule.
  bool _isCurrentlyOpen() {
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final currentHour = now.hour;

    if (_schedule.containsKey(currentWeekday)) {
      final hours = _schedule[currentWeekday]!;
      final openingHour = hours[0];
      final closingHour = hours[1];
      return currentHour >= openingHour && currentHour < closingHour;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isOpen = _isCurrentlyOpen();
    final String statusWord = isOpen ? 'open' : 'closed';
    final Color statusColor = isOpen ? _openColor : _closedColor;

    // Use RichText to style parts of the text differently.
    return RichText(
      text: TextSpan(
        // Default style for the sentence
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
          height: 1.3,
        ),
        children: <TextSpan>[
          const TextSpan(text: 'The gym is currently '),
          TextSpan(
            text: statusWord,
            style: TextStyle(
              color: statusColor,
              
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}