import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/nutrition/states.dart';
import 'package:gloryfit_version_3/services/diet_planner_service.dart';
import 'package:gloryfit_version_3/models/nutrition/foodItem.dart';
import 'package:gloryfit_version_3/models/user_model.dart';

class NutritionCubit extends Cubit<NutritionState> {
  NutritionCubit() : super(const NutritionState());

  final DietPlannerService _plannerService = DietPlannerService();
  List<FoodItem> _allFoods = [];

  /// Helper method to load food data from JSON.
  /// This is called internally and only runs once.
  Future<void> _loadFoods() async {
    if (_allFoods.isNotEmpty) return;
    final jsonString = await rootBundle.loadString('assets/foods_tn.json');
    _allFoods = (json.decode(jsonString) as List).map((j) => FoodItem.fromJson(j)).toList();
  }

  /// Updates the user's preferences in the state.
  /// Called from the UI when a setting is changed.
  void updatePreferences(NutritionPreferences newPreferences) {
    emit(state.copyWith(preferences: newPreferences));
  }

  /// The main action to generate a new, smart diet plan.
  Future<void> generatePlan(UserModel user) async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));
    try {
      await _loadFoods();
      final newPlan = _plannerService.generatePlan(
        user: user,
        allFoods: _allFoods,
        preferences: state.preferences,
      );
      emit(state.copyWith(isLoading: false, dietPlan: newPlan, mealCompletionStatus: {}));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: "Error: ${e.toString()}"));
    }
  }

  /// Replaces a single meal with a new, varied option.
  Future<void> replaceMeal(String mealNameToReplace, UserModel user) async {
    if (state.dietPlan == null) return;
    emit(state.copyWith(isLoading: true));
    
    try {
        await _loadFoods();
        final oldMeal = state.dietPlan!.meals.firstWhere((m) => m.name == mealNameToReplace);
        
        // To ensure variety, we tell the AI about all other foods in the plan.
        final usedFoodNames = state.dietPlan!.meals
            .where((m) => m.name != mealNameToReplace)
            .expand((m) => m.items.map((item) => item.food.name))
            .toSet();

        final newMeal = _plannerService.generateSingleMeal(
            mealName: mealNameToReplace,
            targetCalories: oldMeal.totalCalories,
            allFoods: _allFoods,
            preferences: state.preferences,
            usedFoodNames: usedFoodNames
        );
        
        final updatedMeals = state.dietPlan!.meals.map((m) {
            return m.name == mealNameToReplace ? newMeal : m;
        }).toList();

        // FIXED: Reconstruct the DietPlan object manually to ensure robustness.
        final newPlan = DietPlan(
          meals: updatedMeals,
          AINotes: state.dietPlan!.AINotes,
          targetCalories: state.dietPlan!.targetCalories,
          targetProtein: state.dietPlan!.targetProtein,
          targetCarbs: state.dietPlan!.targetCarbs,
          targetFat: state.dietPlan!.targetFat,
        );

        emit(state.copyWith(
            isLoading: false,
            dietPlan: newPlan
        ));
    } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: "Error replacing meal: ${e.toString()}"));
    }
  }
  
  /// Toggles the completion status of a meal for live tracking on the dashboard.
  void toggleMealCompletion(String mealName) {
    final newStatus = Map<String, bool>.from(state.mealCompletionStatus);
    newStatus[mealName] = !(newStatus[mealName] ?? false);
    emit(state.copyWith(mealCompletionStatus: newStatus));
  }
}
