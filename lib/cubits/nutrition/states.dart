import 'package:equatable/equatable.dart';
import 'package:gloryfit_version_3/models/nutrition/foodItem.dart';

// --- State Models ---

class NutritionPreferences extends Equatable {
  final String dietType;
  final bool isVegetarian;
  final bool isVegan;
  final List<String> allergies;
  final int mealsPerDay;
  final double dailyBudget;

  const NutritionPreferences({
    this.dietType = 'balanced',
    this.isVegetarian = false,
    this.isVegan = false,
    this.allergies = const [],
    this.mealsPerDay = 4,
    this.dailyBudget = 25.0,
  });

  NutritionPreferences copyWith({
    String? dietType,
    bool? isVegetarian,
    bool? isVegan,
    List<String>? allergies,
    int? mealsPerDay,
    double? dailyBudget,
  }) {
    return NutritionPreferences(
      dietType: dietType ?? this.dietType,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      allergies: allergies ?? this.allergies,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      dailyBudget: dailyBudget ?? this.dailyBudget,
    );
  }

  @override
  List<Object?> get props => [dietType, isVegetarian, isVegan, allergies, mealsPerDay, dailyBudget];
}

class NutritionState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final DietPlan? dietPlan;
  final NutritionPreferences preferences;
  final Map<String, bool> mealCompletionStatus;

  const NutritionState({
    this.isLoading = false,
    this.errorMessage,
    this.dietPlan,
    this.preferences = const NutritionPreferences(),
    this.mealCompletionStatus = const {},
  });

  // --- SMART UI GETTERS ---
  bool get hasPlan => dietPlan != null;
  
  bool isMealCompleted(String mealName) => mealCompletionStatus[mealName] ?? false;

  double get consumedCalories => _getConsumedMacro((meal) => meal.totalCalories);
  double get consumedProtein => _getConsumedMacro((meal) => meal.totalProtein);
  double get consumedCarbs => _getConsumedMacro((meal) => meal.totalCarbs);
  double get consumedFat => _getConsumedMacro((meal) => meal.totalFat);

  double _getConsumedMacro(double Function(Meal meal) getValue) {
    if (dietPlan == null) return 0;
    return dietPlan!.meals
        .where((meal) => isMealCompleted(meal.name))
        .fold(0.0, (sum, meal) => sum + getValue(meal));
  }
  // --- END SMART UI GETTERS ---

  NutritionState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    DietPlan? dietPlan,
    bool clearDietPlan = false,
    NutritionPreferences? preferences,
    Map<String, bool>? mealCompletionStatus,
  }) {
    return NutritionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      dietPlan: clearDietPlan ? null : dietPlan ?? this.dietPlan,
      preferences: preferences ?? this.preferences,
      mealCompletionStatus: mealCompletionStatus ?? this.mealCompletionStatus,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, dietPlan, preferences, mealCompletionStatus];
}


// --- DATA MODELS ---

class DietPlan extends Equatable {
  final List<Meal> meals;
  final String AINotes;
  // Store target macros for the UI
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;

  const DietPlan({
    required this.meals, 
    required this.AINotes,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
  });

  double get totalCost => meals.fold(0, (sum, meal) => sum + meal.totalCost);

  @override
  List<Object> get props => [meals, AINotes, targetCalories, targetProtein, targetCarbs, targetFat];
}

class Meal extends Equatable {
  final String name;
  final List<MealItem> items;

  const Meal({required this.name, required this.items});

  double get totalCalories => items.fold(0, (sum, item) => sum + item.calories);
  double get totalProtein => items.fold(0, (sum, item) => sum + item.protein);
  double get totalCarbs => items.fold(0, (sum, item) => sum + item.carbs);
  double get totalFat => items.fold(0, (sum, item) => sum + item.fat);
  double get totalCost => items.fold(0, (sum, item) => sum + item.cost);

  @override
  List<Object> get props => [name, items];
}

class MealItem extends Equatable {
  final FoodItem food;
  final double quantityGrams;

  const MealItem({required this.food, required this.quantityGrams});
  
  double get calories => (food.caloriesPer100g * quantityGrams) / 100;
  double get protein => (food.protein * quantityGrams) / 100;
  double get carbs => (food.carbs * quantityGrams) / 100;
  double get fat => (food.fat * quantityGrams) / 100;
  double get cost => (food.pricePerKg * quantityGrams) / 1000;

  @override
  List<Object> get props => [food, quantityGrams];
}
