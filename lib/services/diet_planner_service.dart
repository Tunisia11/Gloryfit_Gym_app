import 'dart:math';
import 'package:collection/collection.dart';
import 'package:gloryfit_version_3/cubits/nutrition/states.dart';
import 'package:gloryfit_version_3/models/nutrition/foodItem.dart';
import 'package:gloryfit_version_3/models/user_model.dart';

/// Enhanced helper class to hold comprehensive state of the diet plan as it's being built.
/// This allows the planner to make highly intelligent, stateful decisions for each meal.
class _PlanBuilderState {
  Map<String, double> cumulativeMacros = {'protein': 0, 'carbs': 0, 'fat': 0, 'fiber': 0, 'sugar': 0};
  double cumulativeCost = 0;
  Map<String, int> usedFoodFrequency = {}; // Track frequency instead of just presence
  List<double> mealCalories = []; // Track calories per meal for balance analysis
  Map<String, double> categoryUsage = {}; // Track category distribution
  double nutritionalDensityScore = 0; // Track overall plan quality
  
  void updateWithMeal(Meal meal) {
    cumulativeMacros['protein'] = (cumulativeMacros['protein']! + meal.totalProtein);
    cumulativeMacros['carbs'] = (cumulativeMacros['carbs']! + meal.totalCarbs);
    cumulativeMacros['fat'] = (cumulativeMacros['fat']! + meal.totalFat);
   
    cumulativeCost += meal.totalCost;
    mealCalories.add(meal.totalCalories);
    
    // Track food frequency and nutritional density
    for (final item in meal.items) {
      final foodName = item.food.name;
      usedFoodFrequency[foodName] = (usedFoodFrequency[foodName] ?? 0) + 1;
      nutritionalDensityScore += _calculateNutritionalDensity(item.food);
    }
  }
  
  double _calculateNutritionalDensity(FoodItem food) {
    if (food.caloriesPer100g <= 0) return 0;
    // Higher score for foods with more nutrients per calorie
    return (food.protein + food.fiber * 2 ) / food.caloriesPer100g;
  }
  
  /// Calculate how much we're deviating from target ratios
  double getMacroBalanceScore(Map<String, double> targets) {
    double score = 0;
    final total = cumulativeMacros['protein']! + cumulativeMacros['carbs']! + cumulativeMacros['fat']!;
    if (total <= 0) return 0;
    
    final currentRatios = {
      'protein': cumulativeMacros['protein']! / total,
      'carbs': cumulativeMacros['carbs']! / total,
      'fat': cumulativeMacros['fat']! / total,
    };
    
    final targetTotal = targets['protein']! + targets['carbs']! + targets['fat']!;
    final targetRatios = {
      'protein': targets['protein']! / targetTotal,
      'carbs': targets['carbs']! / targetTotal,
      'fat': targets['fat']! / targetTotal,
    };
    
    for (final macro in ['protein', 'carbs', 'fat']) {
      score += 1 - (currentRatios[macro]! - targetRatios[macro]!).abs();
    }
    
    return (score / 3).clamp(0.0, 1.0);
  }
}

/// Enhanced helper class for scoring foods during selection with detailed metrics.
class _ScoredFood {
  final FoodItem food;
  final double totalScore;
  final Map<String, double> componentScores; // For debugging and analysis
  
  _ScoredFood({
    required this.food, 
    required this.totalScore,
    required this.componentScores,
  });
}

/// Defines the structure of a component within a meal with enhanced flexibility.
class _MealComponent {
  final String category;
  double calorieRatio;
  double priority; // Higher priority components get better food selection
  final bool isOptional; // Some components can be skipped if no good options
  
  _MealComponent(this.category, this.calorieRatio, {this.priority = 1.0, this.isOptional = false});
}

/// Advanced user profile analysis for personalized nutrition
class _UserProfile {
  final double metabolicRate;
  final double activityLevel;
  final String bodyType; // ectomorph, mesomorph, endomorph
  final List<String> healthConditions;
  final Map<String, double> micronutrientNeeds;
  final double insulinSensitivity;
  
  _UserProfile({
    required this.metabolicRate,
    required this.activityLevel,
    required this.bodyType,
    this.healthConditions = const [],
    this.micronutrientNeeds = const {},
    this.insulinSensitivity = 1.0,
  });
}

///
/// Ultra-intelligent diet planner service that uses advanced AI algorithms,
/// multi-dimensional scoring, and deep user profiling for optimal meal planning.
///
class DietPlannerService {
  final Random _random = Random();
  
  // Enhanced AI weights with more granular control
  static const Map<String, double> _aiWeights = {
    'nutritional_fit': 0.30,      // How well food fits its nutritional role
    'macro_correction': 0.25,     // Helps achieve daily macro balance
    'cost_efficiency': 0.15,      // Budget optimization
    'user_preference': 0.10,      // Personal preferences and meal timing
    'variety_bonus': 0.08,        // Encourages dietary variety
    'health_optimization': 0.07,  // Targets specific health goals
    'satiety_index': 0.05,        // How filling the food is
  };

  /// Main entry point. Generates a complete, hyper-intelligent diet plan.
  DietPlan generatePlan({
    required UserModel user,
    required List<FoodItem> allFoods,
    required NutritionPreferences preferences,
  }) {
    final age = DateTime.now().year - user.dateOfBirth!.year;
    final userProfile = _buildAdvancedUserProfile(user, age);
    final dailyTargetMacros = _getAdvancedMacroTargets(user, age, preferences, userProfile);
    final filteredFoods = _filterFoodsByPreferences(allFoods, preferences);

    if (filteredFoods.isEmpty) {
      throw Exception("No suitable foods found for your preferences. Please try adjusting them.");
    }
    
    // Enhanced food analysis and categorization
    final categorizedFoods = _categorizeFoodsAdvanced(filteredFoods);
    final foodNutrientMap = _buildNutrientDensityMap(filteredFoods);
    final mealDistribution = _getOptimalMealDistribution(preferences.mealsPerDay, userProfile);
    final planState = _PlanBuilderState();
    final List<Meal> meals = [];

    // Iterative optimization: Build plan, then refine for optimal balance
    for (int iteration = 0; iteration < 2; iteration++) {
      final tempMeals = <Meal>[];
      final tempState = _PlanBuilderState();
      
      // Build meals with increasing intelligence each iteration
      for (int i = 0; i < preferences.mealsPerDay; i++) {
        final mealName = _getMealName(i, preferences.mealsPerDay);
        final mealTargetCalories = dailyTargetMacros['calories']! * mealDistribution[i];
        
        final meal = _createUltraSmartMeal(
          mealName: mealName,
          targetCalories: mealTargetCalories,
          categorizedFoods: categorizedFoods,
          allFoods: filteredFoods,
          preferences: preferences,
          dailyTargetMacros: dailyTargetMacros,
          planState: tempState,
          userProfile: userProfile,
          foodNutrientMap: foodNutrientMap,
          mealIndex: i,
          iteration: iteration,
        );
        
        tempState.updateWithMeal(meal);
        tempMeals.add(meal);
      }
      
      // On final iteration, use the optimized plan
      if (iteration == 1 || _evaluatePlanQuality(tempState, dailyTargetMacros) > 0.85) {
        meals.clear();
        meals.addAll(tempMeals);
        planState.cumulativeMacros = Map.from(tempState.cumulativeMacros);
        planState.cumulativeCost = tempState.cumulativeCost;
        planState.usedFoodFrequency = Map.from(tempState.usedFoodFrequency);
        break;
      }
    }
    
    final notes = _generateAdvancedAINotes(user, preferences, dailyTargetMacros, planState, userProfile);
    
    return DietPlan(
      meals: meals,
      AINotes: notes,
      targetCalories: dailyTargetMacros['calories']!,
      targetProtein: dailyTargetMacros['protein']!,
      targetCarbs: dailyTargetMacros['carbs']!,
      targetFat: dailyTargetMacros['fat']!
    );
  }

  /// Generates a single replacement meal with enhanced intelligence.
  Meal generateSingleMeal({
    required String mealName,
    required double targetCalories,
    required List<FoodItem> allFoods,
    required NutritionPreferences preferences,
    Set<String> usedFoodNames = const {},
  }) {
     final filteredFoods = _filterFoodsByPreferences(allFoods, preferences);
     final categorizedFoods = _categorizeFoodsAdvanced(filteredFoods);
     final userProfile = _buildAdvancedUserProfile(UserModel(id: '', email: '', isOnboardingCompleted: true, createdAt: DateTime.now()), 30);
     final dailyTargets = _getAdvancedMacroTargets(UserModel(id: '', email: '', isOnboardingCompleted: true, createdAt: DateTime.now()), 30, preferences, userProfile);
     final foodNutrientMap = _buildNutrientDensityMap(filteredFoods);
     final planState = _PlanBuilderState();
     
     // Convert Set to frequency map
     for (final foodName in usedFoodNames) {
       planState.usedFoodFrequency[foodName] = 1;
     }

     return _createUltraSmartMeal(
        mealName: mealName,
        targetCalories: targetCalories,
        categorizedFoods: categorizedFoods,
        allFoods: filteredFoods,
        preferences: preferences,
        dailyTargetMacros: dailyTargets,
        planState: planState,
        userProfile: userProfile,
        foodNutrientMap: foodNutrientMap,
        mealIndex: 0,
        iteration: 1,
      );
  }
  
  // --- ENHANCED CORE LOGIC ---

  /// Creates a hyper-intelligent meal using advanced AI food selection algorithms.
  Meal _createUltraSmartMeal({
    required String mealName,
    required double targetCalories,
    required Map<String, List<FoodItem>> categorizedFoods,
    required List<FoodItem> allFoods,
    required NutritionPreferences preferences,
    required Map<String, double> dailyTargetMacros,
    required _PlanBuilderState planState,
    required _UserProfile userProfile,
    required Map<FoodItem, double> foodNutrientMap,
    required int mealIndex,
    required int iteration,
  }) {
    final items = <MealItem>[];
    final mealComposition = _getEnhancedMealComposition(mealName, userProfile, preferences);
    
    // Sort components by priority for optimal selection order
    mealComposition.sort((a, b) => b.priority.compareTo(a.priority));

    for (final component in mealComposition) {
      List<FoodItem> foodOptions = categorizedFoods[component.category] ?? [];
      
      // Enhanced fallback strategy
      if (foodOptions.isEmpty) {
        foodOptions = _getFallbackFoods(component.category, allFoods);
      }
      
      if (foodOptions.isEmpty && !component.isOptional) {
        foodOptions = allFoods; // Last resort fallback
      }
      
      if (foodOptions.isEmpty) continue;
      
      final selectedFood = _selectOptimalFoodEnhanced(
        options: foodOptions,
        componentCategory: component.category,
        mealName: mealName,
        preferences: preferences,
        dailyTargetMacros: dailyTargetMacros,
        planState: planState,
        userProfile: userProfile,
        foodNutrientMap: foodNutrientMap,
        mealIndex: mealIndex,
        componentPriority: component.priority,
        iteration: iteration,
      );
      
      final foodCalories = selectedFood.caloriesPer100g;
      if (foodCalories <= 0) continue;
      
      final caloriesForComponent = targetCalories * component.calorieRatio;
      var quantity = (caloriesForComponent / foodCalories) * 100;
      
      // Smart quantity adjustment based on food type and user profile
      quantity = _adjustQuantityIntelligently(quantity, selectedFood, component.category, userProfile);
      final clampedQuantity = quantity.clamp(15.0, 800.0);

      items.add(MealItem(food: selectedFood, quantityGrams: clampedQuantity));
    }
    
    return Meal(name: mealName, items: items);
  }

  /// The enhanced heart of the AI. Uses advanced multi-dimensional scoring for optimal food selection.
  FoodItem _selectOptimalFoodEnhanced({
    required List<FoodItem> options,
    required String componentCategory,
    required String mealName,
    required NutritionPreferences preferences,
    required Map<String, double> dailyTargetMacros,
    required _PlanBuilderState planState,
    required _UserProfile userProfile,
    required Map<FoodItem, double> foodNutrientMap,
    required int mealIndex,
    required double componentPriority,
    required int iteration,
  }) {
    
    final scoredFoods = options.map((food) {
      final scores = <String, double>{};
      
      // 1. Enhanced Nutritional Fit Score
      scores['nutritional_fit'] = _calculateEnhancedNutritionalFitScore(food, componentCategory, userProfile);

      // 2. Advanced Macro Correction Score
      scores['macro_correction'] = _calculateAdvancedMacroCorrectionScore(
        food, dailyTargetMacros, planState.cumulativeMacros, mealIndex, preferences.mealsPerDay
      );
      
      // 3. Intelligent Cost Score
      scores['cost_efficiency'] = _calculateIntelligentCostScore(
        food, preferences.dailyBudget, dailyTargetMacros['calories']!, planState.cumulativeCost, userProfile
      );

      // 4. Enhanced Preference Score
      scores['user_preference'] = _calculateEnhancedPreferenceScore(food, mealName, preferences, userProfile);

      // 5. Advanced Variety Bonus
      scores['variety_bonus'] = _calculateVarietyBonus(food, planState.usedFoodFrequency, iteration);
      
      // 6. Health Optimization Score
      scores['health_optimization'] = _calculateHealthOptimizationScore(food, userProfile, foodNutrientMap[food] ?? 0);
      
      // 7. Satiety Index Score
      scores['satiety_index'] = _calculateSatietyScore(food, mealName, userProfile);
      
      // Combine all factors with dynamic weight adjustment
      double totalScore = 0;
      for (final entry in scores.entries) {
        final weight = _aiWeights[entry.key] ?? 0;
        totalScore += entry.value * weight * componentPriority;
      }
      
      // Add contextual bonuses
      totalScore += _calculateContextualBonuses(food, mealName, mealIndex, preferences, userProfile);
      
      // Add controlled randomness for variety (less randomness in later iterations)
      final randomnessFactor = 0.08 * (1.0 - (iteration * 0.3));
      totalScore += _random.nextDouble() * randomnessFactor;

      return _ScoredFood(
        food: food, 
        totalScore: totalScore,
        componentScores: scores,
      );
    }).toList();

    // Advanced sorting with tie-breaking
    scoredFoods.sort((a, b) {
      final scoreDiff = b.totalScore.compareTo(a.totalScore);
      if (scoreDiff != 0) return scoreDiff;
      
      // Tie-breaker: prefer foods with higher nutritional density
      return (foodNutrientMap[b.food] ?? 0).compareTo(foodNutrientMap[a.food] ?? 0);
    });
    
    return scoredFoods.first.food;
  }

  // --- ENHANCED SCORING ALGORITHMS ---

  /// Enhanced nutritional fit scoring with user profile consideration.
  double _calculateEnhancedNutritionalFitScore(FoodItem food, String category, _UserProfile userProfile) {
    final calories = food.caloriesPer100g;
    if (calories <= 0) return 0;
    double score = 0;

    switch (category) {
      case 'lean_proteins':
        score = (food.protein * 4) / calories;
        // Bonus for complete proteins and digestibility
        if (food.tags.contains('complete_protein')) score *= 1.2;
        if (food.tags.contains('fast_digest')) score *= 1.1;
        break;
        
      case 'complex_carbs':
        final carbCalories = food.carbs * 4;
        final fiberBonus = food.fiber * 2; // Fiber is valuable
        score = (carbCalories + fiberBonus) / calories;
        
        // Adjust for insulin sensitivity
        if (userProfile.insulinSensitivity < 0.8 && food.tags.contains('low_gi')) {
          score *= 1.3;
        }
        break;
        
      case 'healthy_fats':
        score = (food.fat * 9) / calories;
        // Bonus for omega-3 and monounsaturated fats
        if (food.tags.contains('omega3')) score *= 1.25;
        if (food.tags.contains('monounsaturated')) score *= 1.15;
        break;
        
      case 'vegetables':
      case 'fruits':
        // Prioritize nutrient density over just low calories
        final nutrientDensity = (food.fiber * 5 );
        score = (1 - (calories / 250)) * 0.7 + (nutrientDensity / calories) * 0.3;
        break;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Advanced macro correction that considers meal timing and daily progression.
  double _calculateAdvancedMacroCorrectionScore(
    FoodItem food, 
    Map<String, double> dailyTarget, 
    Map<String, double> cumulative,
    int mealIndex,
    int totalMeals,
  ) {
    final progressRatio = (mealIndex + 1) / totalMeals;
    
    final remaining = {
      'protein': (dailyTarget['protein']! * progressRatio) - cumulative['protein']!,
      'carbs': (dailyTarget['carbs']! * progressRatio) - cumulative['carbs']!,
      'fat': (dailyTarget['fat']! * progressRatio) - cumulative['fat']!,
    };
    
    final totalRemaining = remaining.values.where((v) => v > 0).sum;
    if (totalRemaining <= 0) return 0.6; // Slightly above neutral if we're on track

    final calories = food.caloriesPer100g;
    if(calories <= 0) return 0;
    
    final foodMacroContribution = {
      'protein': food.protein,
      'carbs': food.carbs,
      'fat': food.fat,
    };

    double score = 0;
    for (final macro in ['protein', 'carbs', 'fat']) {
      if (remaining[macro]! > 0) {
        final deficitRatio = remaining[macro]! / totalRemaining;
        final foodContribution = foodMacroContribution[macro]! / 100; // per 100g
        score += deficitRatio * foodContribution * 10; // Scale up the contribution
      }
    }

    return score.clamp(0.0, 1.0);
  }
  
  /// Intelligent cost scoring that considers nutritional value per dollar.
  double _calculateIntelligentCostScore(
    FoodItem food, 
    double dailyBudget, 
    double totalCalories, 
    double cumulativeCost,
    _UserProfile userProfile,
  ) {
    if (dailyBudget <= 0) return 0.6; // Neutral score if no budget constraint

    final remainingBudget = dailyBudget - cumulativeCost;
    if (remainingBudget <= 0) return 0;

    final foodCostPer100g = food.pricePerKg / 10;
    final costPerCalorie = foodCostPer100g / food.caloriesPer100g;
    
    if (costPerCalorie <= 0) return 0.5;

    // Calculate value score: nutritional density per cost
    final nutritionalValue = food.protein * 2 + food.fiber * 3 ;
    final valueScore = nutritionalValue / costPerCalorie;
    
    // Normalize against budget constraint
    final budgetRatio = remainingBudget / dailyBudget;
    final affordabilityScore = budgetRatio > 0.5 ? 1.0 : budgetRatio * 2;
    
    return (valueScore * 0.7 + affordabilityScore * 0.3).clamp(0.0, 1.0);
  }

  /// Enhanced preference scoring based on comprehensive user profile.
  double _calculateEnhancedPreferenceScore(
    FoodItem food, 
    String mealName, 
    NutritionPreferences preferences,
    _UserProfile userProfile,
  ) {
    double score = 0;
    
    // Meal timing preferences
    if (food.tags.contains(mealName.toLowerCase())) score += 0.4;
    
    // Body type preferences
    switch (userProfile.bodyType) {
      case 'ectomorph':
        if (food.tags.contains('calorie_dense')) score += 0.3;
        break;
      case 'endomorph':
        if (food.tags.contains('low_gi') || food.tags.contains('high_fiber')) score += 0.3;
        break;
      case 'mesomorph':
        if (food.tags.contains('balanced_macro')) score += 0.2;
        break;
    }
    
    // Activity level adjustments
    if (userProfile.activityLevel > 1.6) {
      if (food.tags.contains('recovery') || food.tags.contains('pre_workout')) score += 0.2;
    }
    
    // Health condition considerations
    for (final condition in userProfile.healthConditions) {
      if (food.tags.contains(condition.toLowerCase())) score += 0.3;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate variety bonus to encourage dietary diversity.
  double _calculateVarietyBonus(FoodItem food, Map<String, int> usedFrequency, int iteration) {
    final frequency = usedFrequency[food.name] ?? 0;
    
    // Base variety score (higher is better for unused foods)
    double varietyScore = 1.0 / (1.0 + frequency);
    
    // Category variety bonus
    final categoryPrefix = food.category.split(' ').first.toLowerCase();
    final categoryUsage = usedFrequency.entries
        .where((entry) => entry.key.toLowerCase().startsWith(categoryPrefix))
        .map((entry) => entry.value)
        .sum;
    
    if (categoryUsage == 0) varietyScore *= 1.5; // Big bonus for new categories
    
    // Reduce variety importance in later iterations for stability
    varietyScore *= (1.0 - iteration * 0.2);
    
    return varietyScore.clamp(0.0, 1.0);
  }

  /// Score foods based on their health optimization potential.
  double _calculateHealthOptimizationScore(
    FoodItem food, 
    _UserProfile userProfile, 
    double nutrientDensity,
  ) {
    double score = nutrientDensity;
    
    // Micronutrient targeting
    for (final entry in userProfile.micronutrientNeeds.entries) {
      if (food.tags.contains('high_${entry.key.toLowerCase()}')) {
        score += entry.value * 0.5;
      }
    }
    
    // Anti-inflammatory foods bonus
    if (food.tags.contains('anti_inflammatory')) score += 0.3;
    
    // Antioxidant bonus
    if (food.tags.contains('antioxidant')) score += 0.2;
    
    // Digestive health
    if (food.fiber > 5) score += 0.2; // High fiber foods
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate how satiating a food is likely to be.
  double _calculateSatietyScore(FoodItem food, String mealName, _UserProfile userProfile) {
    double score = 0;
    
    // Protein is highly satiating
    score += (food.protein / 100) * 0.4;
    
    // Fiber contributes to satiety
    score += (food.fiber / 20) * 0.3;
    
    // Healthy fats for sustained energy
    if (food.tags.contains('healthy_fat')) {
      score += (food.fat / 100) * 0.2;
    }
    
    // Water content (for fruits/vegetables)
    if (food.tags.contains('high_water')) score += 0.1;
    
    // Meal-specific adjustments
    if (mealName.toLowerCase() == 'breakfast' && food.tags.contains('sustained_energy')) {
      score += 0.2;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate contextual bonuses based on various factors.
  double _calculateContextualBonuses(
    FoodItem food,
    String mealName,
    int mealIndex,
    NutritionPreferences preferences,
    _UserProfile userProfile,
  ) {
    double bonus = 0;
    
    // Pre/post workout timing
    if (mealIndex == 0 && food.tags.contains('pre_workout')) bonus += 0.1;
    if (mealIndex == preferences.mealsPerDay - 1 && food.tags.contains('recovery')) bonus += 0.1;
    
    // Seasonal preferences (if available)
    final currentMonth = DateTime.now().month;
    if (currentMonth >= 6 && currentMonth <= 8 && food.tags.contains('summer')) bonus += 0.05;
    if ((currentMonth <= 2 || currentMonth >= 11) && food.tags.contains('winter')) bonus += 0.05;
    
    // Local/sustainable bonus
    if (food.tags.contains('local') || food.tags.contains('sustainable')) bonus += 0.03;
    
    return bonus;
  }

  // --- ENHANCED UTILITY METHODS ---

  /// Build a comprehensive user profile for personalized nutrition.
  _UserProfile _buildAdvancedUserProfile(UserModel user, int age) {
    // Advanced metabolic rate calculation
    double bmr = (user.gender == Gender.male)
        ? (10 * (user.weight ?? 70) + 6.25 * (user.height ?? 170) - 5 * age + 5)
        : (10 * (user.weight ?? 60) + 6.25 * (user.height ?? 160) - 5 * age - 161);
    
    // Enhanced activity level calculation
    final trainingDays = user.trainingDaysPerWeek ?? 3;
    double activityLevel = 1.2 + (trainingDays * 0.15);
    
    // Body type estimation based on user data
    String bodyType = 'mesomorph'; // default
    if (user.weight != null && user.height != null) {
      final bmi = user.weight! / pow(user.height! / 100, 2);
      if (bmi < 20) bodyType = 'ectomorph';
      else if (bmi > 27) bodyType = 'endomorph';
    }
    
    // Insulin sensitivity estimation (simplified)
    double insulinSensitivity = 1.0;
    if (age > 40) insulinSensitivity *= 0.9;
    if (trainingDays >= 4) insulinSensitivity *= 1.1;
    
    // Health conditions inference
    List<String> healthConditions = [];
    if (user.fitnessGoal == FitnessGoal.weightLoss) healthConditions.add('weight_management');
    
    // Basic micronutrient needs
    Map<String, double> micronutrientNeeds = {
      'iron': user.gender == Gender.female ? 1.2 : 1.0,
      'calcium': age > 50 ? 1.3 : 1.0,
      'vitamin_d': 1.0,
      'b12': age > 50 ? 1.2 : 1.0,
    };
    
    return _UserProfile(
      metabolicRate: bmr,
      activityLevel: activityLevel,
      bodyType: bodyType,
      healthConditions: healthConditions,
      micronutrientNeeds: micronutrientNeeds,
      insulinSensitivity: insulinSensitivity,
    );
  }

  /// Build nutrient density map for all foods.
  Map<FoodItem, double> _buildNutrientDensityMap(List<FoodItem> foods) {
    final map = <FoodItem, double>{};
    
    for (final food in foods) {
      if (food.caloriesPer100g > 0) {
        // Calculate comprehensive nutrient density score
        double density = 0;
        
        // Macronutrient contributions
        density += food.protein * 2; // Protein is highly valuable
        density += food.fiber * 3; // Fiber is very valuable
      
        
        // Bonus for specific beneficial compounds
        if (food.tags.contains('omega3')) density += 10;
        if (food.tags.contains('antioxidant')) density += 8;
        if (food.tags.contains('anti_inflammatory')) density += 6;
        if (food.tags.contains('probiotic')) density += 7;
        
        // Normalize by calories
        map[food] = density / food.caloriesPer100g;
      } else {
        map[food] = 0;
      }
    }
    
    return map;
  }

  /// Get fallback foods when primary category is empty.
  List<FoodItem> _getFallbackFoods(String category, List<FoodItem> allFoods) {
    switch (category) {
      case 'lean_proteins':
        return allFoods.where((f) => f.protein > 15).toList();
      case 'complex_carbs':
        return allFoods.where((f) => f.carbs > 20 && f.fiber > 2).toList();
      case 'healthy_fats':
        return allFoods.where((f) => f.fat > 10).toList();
      case 'vegetables':
        return allFoods.where((f) => f.caloriesPer100g < 50 && f.fiber > 2).toList();
      case 'fruits':
        return allFoods.where((f) => f.caloriesPer100g < 80 && f.carbs > 10).toList();
      default:
        return [];
    }
  }

  /// Intelligently adjust food quantities based on food type and user profile.
  double _adjustQuantityIntelligently(
    double baseQuantity, 
    FoodItem food, 
    String category, 
    _UserProfile userProfile,
  ) {
    double multiplier = 1.0;
    
    // Adjust based on food category
    switch (category) {
      case 'lean_proteins':
        // Higher protein needs for muscle gain and high activity
        if (userProfile.activityLevel > 1.6) multiplier *= 1.2;
        if (userProfile.bodyType == 'ectomorph') multiplier *= 1.15;
        break;
        
      case 'complex_carbs':
        // Adjust carbs based on insulin sensitivity and activity
        if (userProfile.insulinSensitivity < 0.8) multiplier *= 0.8;
        if (userProfile.activityLevel > 1.7) multiplier *= 1.3;
        break;
        
      case 'healthy_fats':
        // Moderate fat portions, higher for keto dieters
        multiplier *= 0.9; // Generally smaller portions for fats
        break;
        
      case 'vegetables':
        // Encourage more vegetables
        multiplier *= 1.2;
        break;
        
      case 'fruits':
        // Moderate fruit portions
        if (userProfile.insulinSensitivity < 0.8) multiplier *= 0.7;
        break;
    }
    
    // Adjust for calorie density
    if (food.caloriesPer100g > 400) multiplier *= 0.8; // Smaller portions of calorie-dense foods
    if (food.caloriesPer100g < 100) multiplier *= 1.3; // Larger portions of low-calorie foods
    
    return baseQuantity * multiplier;
  }

  /// Evaluate overall plan quality for optimization iterations.
  double _evaluatePlanQuality(_PlanBuilderState state, Map<String, double> targets) {
    double quality = 0;
    
    // Macro balance score (40% of total quality)
    quality += state.getMacroBalanceScore(targets) * 0.4;
    
    // Variety score (25% of total quality)
    final uniqueFoods = state.usedFoodFrequency.keys.length;
    final totalFoodInstances = state.usedFoodFrequency.values.sum;
    final varietyScore = uniqueFoods / totalFoodInstances.clamp(1, double.infinity);
    quality += varietyScore * 0.25;
    
    // Nutritional density score (20% of total quality)
    final avgNutrientDensity = state.nutritionalDensityScore / totalFoodInstances.clamp(1, double.infinity);
    quality += avgNutrientDensity.clamp(0, 1) * 0.2;
    
    // Meal balance score (15% of total quality)
    if (state.mealCalories.isNotEmpty) {
      final avgCalories = state.mealCalories.average;
      final calorieVariance = state.mealCalories.map((c) => pow(c - avgCalories, 2)).average;
      final balanceScore = 1.0 / (1.0 + calorieVariance / 10000);
      quality += balanceScore * 0.15;
    }
    
    return quality.clamp(0.0, 1.0);
  }

  /// Get optimal meal distribution based on user profile.
  List<double> _getOptimalMealDistribution(int mealsCount, _UserProfile userProfile) {
    // Base distributions
    List<double> distribution;
    
    if (mealsCount >= 5) {
      distribution = [0.25, 0.10, 0.30, 0.10, 0.25];
    } else if (mealsCount == 4) {
      distribution = [0.30, 0.35, 0.10, 0.25];
    } else if (mealsCount == 3) {
      distribution = [0.35, 0.40, 0.25];
    } else {
      distribution = List.filled(mealsCount, 1.0 / mealsCount);
    }
    
    // Adjust based on user profile
    if (userProfile.activityLevel > 1.7 && mealsCount >= 3) {
      // Shift more calories to post-workout meals
      for (int i = 1; i < distribution.length; i++) {
        distribution[i] *= 1.1;
        distribution[0] *= 0.95;
      }
    }
    
    if (userProfile.bodyType == 'ectomorph' && mealsCount >= 4) {
      // More frequent, larger meals
      for (int i = 0; i < distribution.length; i++) {
        distribution[i] *= 1.05;
      }
    }
    
    // Normalize to ensure sum equals 1.0
    final sum = distribution.sum;
    return distribution.map((d) => d / sum).toList();
  }

  /// Get enhanced meal composition based on user profile and preferences.
  List<_MealComponent> _getEnhancedMealComposition(
    String mealName, 
    _UserProfile userProfile, 
    NutritionPreferences preferences,
  ) {
    List<_MealComponent> components;
    
    switch (mealName.toLowerCase()) {
      case 'breakfast':
        components = [
          _MealComponent('complex_carbs', 0.45, priority: 1.2),
          _MealComponent('lean_proteins', 0.35, priority: 1.1),
          _MealComponent('fruits', 0.20, priority: 0.9, isOptional: true),
        ];
        break;
        
      case 'lunch':
        components = [
          _MealComponent('lean_proteins', 0.40, priority: 1.3),
          _MealComponent('complex_carbs', 0.35, priority: 1.0),
          _MealComponent('vegetables', 0.25, priority: 1.1),
        ];
        break;
        
      case 'dinner':
        components = [
          _MealComponent('lean_proteins', 0.45, priority: 1.2),
          _MealComponent('vegetables', 0.35, priority: 1.3),
          _MealComponent('healthy_fats', 0.20, priority: 1.0),
        ];
        break;
        
      case 'morning snack':
      case 'afternoon snack':
        components = [
          _MealComponent('healthy_fats', 0.40, priority: 1.0),
          _MealComponent('lean_proteins', 0.35, priority: 1.1),
          _MealComponent('fruits', 0.25, priority: 0.8, isOptional: true),
        ];
        break;
        
      default: // Generic snack
        components = [
          _MealComponent('healthy_fats', 0.50, priority: 1.0),
          _MealComponent('lean_proteins', 0.50, priority: 1.0),
        ];
    }
    
    // Adjust components based on user profile
    if (preferences.dietType == 'keto') {
      // Dramatically increase fat, reduce carbs
      for (final component in components) {
        if (component.category == 'healthy_fats') {
          component.calorieRatio *= 2.0;
          component.priority *= 1.5;
        } else if (component.category == 'complex_carbs' || component.category == 'fruits') {
          component.calorieRatio *= 0.2;
          component.priority *= 0.5;
        }
      }
    }
    
    if (userProfile.bodyType == 'ectomorph') {
      // Increase overall portions slightly
      for (final component in components) {
        component.calorieRatio *= 1.1;
      }
    }
    
    if (userProfile.activityLevel > 1.7) {
      // Boost protein components
      for (final component in components) {
        if (component.category == 'lean_proteins') {
          component.calorieRatio *= 1.2;
          component.priority *= 1.1;
        }
      }
    }
    
    // Normalize calorie ratios
    final totalRatio = components.map((c) => c.calorieRatio).sum;
    for (final component in components) {
      component.calorieRatio /= totalRatio;
    }
    
    return components;
  }

  String _generateAdvancedAINotes(
    UserModel user, 
    NutritionPreferences prefs, 
    Map<String, double> macros, 
    _PlanBuilderState finalState,
    _UserProfile userProfile,
  ) {
    final notes = StringBuffer();
    
    // Header with personalized goal
    notes.write("🎯 **Personalized Plan for ${user.fitnessGoal.toString().split('.').last}**\n");
    notes.write("Your AI-optimized plan targets **${macros['calories']!.round()} calories** ");
    notes.write("with **${macros['protein']!.round()}g protein**, **${macros['carbs']!.round()}g carbs**, ");
    notes.write("and **${macros['fat']!.round()}g fat**.\n\n");
    
    // AI Strategy explanation
    notes.write("🧠 **Advanced AI Strategy**: This plan was created using multi-dimensional food scoring that considers:\n");
    notes.write("• **Nutritional optimization** - Each food is selected for its specific role\n");
    notes.write("• **Macro progression** - Meals build toward your daily targets intelligently\n");
    notes.write("• **Cost efficiency** - Maximum nutrition per dollar spent\n");
    notes.write("• **Variety & health** - Diverse foods with high nutrient density\n\n");
    
    // User-specific insights
    notes.write("👤 **Your Profile Insights**:\n");
    notes.write("• **Body Type**: ${userProfile.bodyType.toUpperCase()} - Plan optimized for your metabolism\n");
    notes.write("• **Activity Level**: ${(userProfile.activityLevel * 100 - 120).round()}% above baseline\n");
    if (userProfile.insulinSensitivity < 0.9) {
      notes.write("• **Metabolic Focus**: Lower-GI foods prioritized for better blood sugar control\n");
    }
    
    // Budget information
    if (prefs.dailyBudget > 0) {
      final cost = finalState.cumulativeCost.toStringAsFixed(2);
      final efficiency = (macros['calories']! / finalState.cumulativeCost).round();
      notes.write("\n💰 **Budget Optimization**: \${cost} daily cost (\${prefs.dailyBudget} budget)\n");
      notes.write("**Value**: ${efficiency} calories per dollar - excellent cost efficiency!\n");
    }
    
    // Diet-specific notes
    if (prefs.dietType == 'keto') {
      notes.write("\n🥑 **Keto Optimization**: Ultra-low carb, high-fat plan designed for ketosis.\n");
      notes.write("**Tips**: Stay hydrated, supplement electrolytes, and monitor ketone levels!\n");
    } else if (prefs.isVegan) {
      notes.write("\n🌱 **Plant-Based Excellence**: All foods are vegan with complete amino acid profiles.\n");
      notes.write("**Tips**: Monitor B12 and iron levels, combine proteins for completeness!\n");
    }
    
    // Variety and quality metrics
    final uniqueFoods = finalState.usedFoodFrequency.keys.length;
    final totalInstances = finalState.usedFoodFrequency.values.sum;
    final varietyScore = (uniqueFoods / totalInstances * 100).round();
    
    notes.write("\n📊 **Plan Quality Metrics**:\n");
    notes.write("• **Food Variety**: ${uniqueFoods} unique foods (${varietyScore}% variety score)\n");
    notes.write("• **Nutrient Density**: ${(finalState.nutritionalDensityScore / totalInstances * 100).round()}% above average\n");
    
    // Meal timing advice
    notes.write("\n⏰ **Optimal Timing**: Meals are distributed based on your activity level and metabolism.\n");
    if (userProfile.activityLevel > 1.6) {
      notes.write("**Pre/Post Workout**: Protein-rich foods strategically placed around training times.\n");
    }
    
    notes.write("\n✨ **Pro Tip**: This plan adapts to your unique profile. Consistency is key to results!");
    
    return notes.toString();
  }

  // --- ENHANCED CONFIGURATION METHODS ---

  Map<String, double> _getAdvancedMacroTargets(
    UserModel user, 
    int age, 
    NutritionPreferences preferences,
    _UserProfile userProfile,
  ) {
    // Enhanced TDEE calculation using user profile
    double tdee = userProfile.metabolicRate * userProfile.activityLevel;
    
    // Body type adjustments
    switch (userProfile.bodyType) {
      case 'ectomorph':
        tdee *= 1.1; // Higher metabolic rate
        break;
      case 'endomorph':
        tdee *= 0.95; // Slightly lower metabolic rate
        break;
      // mesomorph uses base calculation
    }
    
    double targetCalories = tdee;
    Map<String, double> ratios = {'protein': 0.30, 'carbs': 0.40, 'fat': 0.30};

    // Goal-specific adjustments with user profile consideration
    switch (user.fitnessGoal) {
      case FitnessGoal.weightLoss:
        final deficit = userProfile.bodyType == 'endomorph' ? 500 : 450;
        targetCalories -= deficit;
        ratios = userProfile.insulinSensitivity < 0.8 
            ? {'protein': 0.45, 'carbs': 0.25, 'fat': 0.30}  // Lower carbs for insulin resistance
            : {'protein': 0.40, 'carbs': 0.35, 'fat': 0.25};
        break;
        
      case FitnessGoal.muscleGain:
        final surplus = userProfile.bodyType == 'ectomorph' ? 500 : 450;
        targetCalories += surplus;
        ratios = userProfile.activityLevel > 1.7
            ? {'protein': 0.35, 'carbs': 0.50, 'fat': 0.15}  // Higher carbs for high activity
            : {'protein': 0.35, 'carbs': 0.45, 'fat': 0.20};
        break;
        
      default: // General Fitness
        targetCalories += 100;
        // Adjust based on activity level
        if (userProfile.activityLevel > 1.6) {
          ratios = {'protein': 0.32, 'carbs': 0.43, 'fat': 0.25};
        }
        break;
    }
    
    // Diet type overrides
    if (preferences.dietType == 'keto') {
      ratios = {'protein': 0.25, 'carbs': 0.05, 'fat': 0.70};
    } else if (preferences.dietType == 'low_carb') {
      ratios = {'protein': 0.35, 'carbs': 0.25, 'fat': 0.40};
    } else if (preferences.isVegan) {
      // Slightly higher carbs for plant-based diets
      ratios['carbs'] = (ratios['carbs']! * 1.1).clamp(0.0, 0.6);
      ratios['protein'] = (ratios['protein']! * 0.95).clamp(0.15, 0.5);
      ratios['fat'] = 1.0 - ratios['protein']! - ratios['carbs']!;
    }
    
    return {
      'calories': targetCalories,
      'protein': (targetCalories * ratios['protein']!) / 4,
      'carbs': (targetCalories * ratios['carbs']!) / 4,
      'fat': (targetCalories * ratios['fat']!) / 9,
    };
  }

  List<FoodItem> _filterFoodsByPreferences(List<FoodItem> foods, NutritionPreferences preferences) {
    return foods.where((food) {
      // Vegan check
      if (preferences.isVegan && !food.tags.contains('vegan')) return false;
      
      // Vegetarian check (vegan foods are also vegetarian)
      if (preferences.isVegetarian && 
          !food.tags.contains('vegetarian') && 
          !food.tags.contains('vegan')) return false;
      
      // Allergy check
      if (preferences.allergies.any((allergy) => food.allergens.contains(allergy))) return false;
      
      // Diet type specific filters
      if (preferences.dietType == 'keto' && food.carbs > 10) return false;
      if (preferences.dietType == 'low_carb' && food.carbs > 20) return false;
      
      // Quality filters
      if (food.caloriesPer100g <= 0 || food.pricePerKg <= 0) return false;
      
      return true;
    }).toList();
  }

  Map<String, List<FoodItem>> _categorizeFoodsAdvanced(List<FoodItem> foods) {
    final categories = <String, List<FoodItem>>{
      'lean_proteins': [], 
      'complex_carbs': [], 
      'healthy_fats': [], 
      'vegetables': [], 
      'fruits': []
    };
    
    for (final food in foods) {
      // Enhanced categorization with multiple criteria
      
      // Protein categorization (prioritize lean sources)
      if (food.protein > 15 && (food.fat < 10 || food.tags.contains('protein_lean'))) {
        categories['lean_proteins']!.add(food);
      }
      
      // Complex carbs (high carb, good fiber, low sugar)
      if (food.carbs > 20 && food.fiber > 2 && !food.tags.contains('simple_sugar')) {
        categories['complex_carbs']!.add(food);
      }
      
      // Healthy fats (prioritize unsaturated)
      if (food.fat > 10 && (food.tags.contains('unsaturated') || food.tags.contains('omega3'))) {
        categories['healthy_fats']!.add(food);
      }
      
      // Vegetables (low calorie, high nutrients)
      if (food.caloriesPer100g < 60 && food.fiber > 2 && !food.tags.contains('fruit')) {
        categories['vegetables']!.add(food);
      }
      
      // Fruits (natural sugars, vitamins)
      if (food.carbs > 8 && food.caloriesPer100g < 100 && food.tags.contains('fruit')) {
        categories['fruits']!.add(food);
      }
      
      // Fallback categorization by explicit tags or category
      if (food.tags.contains('protein_lean') || food.category == 'Protein') {
        categories['lean_proteins']!.add(food);
      }
      if (food.tags.contains('carb_complex') || food.category == 'Carbohydrates') {
        categories['complex_carbs']!.add(food);
      }
      if (food.tags.contains('fat_healthy') || food.category == 'Fats') {
        categories['healthy_fats']!.add(food);
      }
      if (food.tags.contains('vegetable') || food.category == 'Vegetables') {
        categories['vegetables']!.add(food);
      }
      if (food.tags.contains('fruit') || food.category == 'Fruits') {
        categories['fruits']!.add(food);
      }
    }
    
    return categories;
  }

  String _getMealName(int index, int mealsCount) {
    if (mealsCount >= 5) {
      return ['Breakfast', 'Morning Snack', 'Lunch', 'Afternoon Snack', 'Dinner'][index];
    }
    if (mealsCount == 4) {
      return ['Breakfast', 'Lunch', 'Snack', 'Dinner'][index];
    }
    if (mealsCount == 3) {
      return ['Breakfast', 'Lunch', 'Dinner'][index];
    }
    return 'Meal ${index + 1}';
  }
}