import 'package:equatable/equatable.dart';

class FoodItem extends Equatable {
  final String name;
  final String category;
  final double caloriesPer100g;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double pricePerKg;
  final List<String> tags;
  final List<String> allergens;

  const FoodItem({
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.pricePerKg,
    required this.tags,
    required this.allergens,
  });

  /// A robust factory constructor that handles null or missing data from JSON.
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      // Provide a default for String fields
      name: json['name'] ?? 'Unnamed Food',
      category: json['category'] ?? 'uncategorized',

      // Provide a default for numeric fields
      // The `?? 0` handles null, and `toDouble()` handles if it's an integer like `150`
      caloriesPer100g: (json['calories_per_100g'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      pricePerKg: (json['price_per_kg'] ?? 0).toDouble(),
      
      // Provide a default empty list for List fields
      tags: List<String>.from(json['tags'] ?? []),
      allergens: List<String>.from(json['allergens'] ?? []),
    );
  }
  
  @override
  List<Object?> get props => [
    name, category, caloriesPer100g, protein, carbs, fat, fiber, pricePerKg, tags, allergens
  ];
}