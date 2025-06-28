import 'package:cloud_firestore/cloud_firestore.dart';

// Represents the nutritional summary for a single day.
class DailyNutritionRecord {
  final DateTime date;
  final double caloriesConsumed;
  final double caloriesTarget;
  final double proteinConsumed;
  final double proteinTarget;
  final double carbsConsumed;
  final double carbsTarget;
  final double fatConsumed;
  final double fatTarget;
  final bool goalMet; // Was the user within a tolerance of their calorie goal?
  
  DailyNutritionRecord({
    required this.date,
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.fatConsumed,
    required this.fatTarget,
  }) : goalMet = (caloriesConsumed - caloriesTarget).abs() < (caloriesTarget * 0.1); // e.g. within 10%

  // Convert to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'caloriesConsumed': caloriesConsumed,
      'caloriesTarget': caloriesTarget,
      'proteinConsumed': proteinConsumed,
      'proteinTarget': proteinTarget,
      'carbsConsumed': carbsConsumed,
      'carbsTarget': carbsTarget,
      'fatConsumed': fatConsumed,
      'fatTarget': fatTarget,
      'goalMet': goalMet,
    };
  }

  // Create from a Firestore document
  factory DailyNutritionRecord.fromMap(Map<String, dynamic> map) {
    return DailyNutritionRecord(
      date: (map['date'] as Timestamp).toDate(),
      caloriesConsumed: (map['caloriesConsumed'] as num).toDouble(),
      caloriesTarget: (map['caloriesTarget'] as num).toDouble(),
      proteinConsumed: (map['proteinConsumed'] as num).toDouble(),
      proteinTarget: (map['proteinTarget'] as num).toDouble(),
      carbsConsumed: (map['carbsConsumed'] as num).toDouble(),
      carbsTarget: (map['carbsTarget'] as num).toDouble(),
      fatConsumed: (map['fatConsumed'] as num).toDouble(),
      fatTarget: (map['fatTarget'] as num).toDouble(),
    );
  }
}