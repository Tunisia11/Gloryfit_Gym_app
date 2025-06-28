import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/nutrition/cubit.dart';
import 'package:gloryfit_version_3/cubits/nutrition/states.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:animate_do/animate_do.dart';

// --- Main Screen Widget ---
class NutritionDashboardScreen extends StatelessWidget {
  const NutritionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NutritionCubit(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          appBar: AppBar(
            title: const Text('Nutrition AI', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.1),
            centerTitle: true,
            bottom: TabBar(
              indicatorColor: Colors.redAccent,
              labelColor: Colors.redAccent,
              unselectedLabelColor: Colors.grey[600],
              indicatorWeight: 3.0,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
                Tab(icon: Icon(Icons.edit_note_rounded), text: 'Plan Details'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [ _DashboardTab(), _PlanDetailsTab() ],
          ),
        ),
      ),
    );
  }
}

// --- Tab 1: Live Tracking Dashboard ---
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NutritionCubit, NutritionState>(
      builder: (context, state) {
        if (state.isLoading && !state.hasPlan) { return const _LoadingView(); }
        if (!state.hasPlan) {
          return _EmptyStateView(
            onAction: () => _showSettingsSheet(context),
            actionText: 'Create Your First Smart Plan',
          );
        }
        return _LiveTrackingDashboard(state: state);
      },
    );
  }
}

// --- Tab 2: Planner Settings & Meal Details ---
class _PlanDetailsTab extends StatelessWidget {
  const _PlanDetailsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NutritionCubit, NutritionState>(
      builder: (context, state) {
        if (state.isLoading && !state.hasPlan) { return const _LoadingView(); }
        if (!state.hasPlan) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ElevatedButton.icon(
                onPressed: () => _showSettingsSheet(context),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Configure Your Plan'),
              ),
            ),
          );
        }
        return _DietPlanView(plan: state.dietPlan!);
      },
    );
  }
}

// --- UI WIDGETS ---

class _LiveTrackingDashboard extends StatelessWidget {
  final NutritionState state;
  const _LiveTrackingDashboard({required this.state});

  @override
  Widget build(BuildContext context) {
    final plan = state.dietPlan!;
    return RefreshIndicator(
      onRefresh: () async {
         final user = (context.read<UserCubit>().state as dynamic).user as UserModel;
         context.read<NutritionCubit>().generatePlan(user);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeInDown(
            child: Text("Today's Progress", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
              children: [
                _MacroGauge(title: 'Calories', consumed: state.consumedCalories, total: plan.targetCalories, color: Colors.redAccent, unit: 'kcal'),
                _MacroGauge(title: 'Protein', consumed: state.consumedProtein, total: plan.targetProtein, color: Colors.blueAccent, unit: 'g'),
                _MacroGauge(title: 'Carbs', consumed: state.consumedCarbs, total: plan.targetCarbs, color: Colors.orangeAccent, unit: 'g'),
                _MacroGauge(title: 'Fat', consumed: state.consumedFat, total: plan.targetFat, color: Colors.purpleAccent, unit: 'g'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FadeInUp(delay: const Duration(milliseconds: 200), child: Text("Meals", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          ...plan.meals.map((meal) {
            int index = plan.meals.indexOf(meal);
            return FadeInUp(
              delay: Duration(milliseconds: 300 + (index * 100)),
              child: _MealCheckCard(meal: meal, isCompleted: state.isMealCompleted(meal.name), onToggle: () => context.read<NutritionCubit>().toggleMealCompletion(meal.name)),
            );
          })
        ],
      ),
    );
  }
}

class _DietPlanView extends StatelessWidget {
  final DietPlan plan;
  const _DietPlanView({required this.plan});

  @override
  Widget build(BuildContext context) {
    final user = (context.read<UserCubit>().state as dynamic).user as UserModel;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AiInsightCard(notes: plan.AINotes),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Your Meal Schedule", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.grey),
              onPressed: () => _showSettingsSheet(context),
            )
          ],
        ),
        const SizedBox(height: 16),
        ...plan.meals.map((meal) => _MealDetailCard(meal: meal, onReplace: () => context.read<NutritionCubit>().replaceMeal(meal.name, user)))
      ],
    );
  }
}

// --- CUSTOM COMPONENTS ---

class _MacroGauge extends StatelessWidget {
  final String title; final Color color; final double consumed; final double total; final String unit;
  const _MacroGauge({required this.title, required this.color, required this.consumed, required this.total, required this.unit});

  @override
  Widget build(BuildContext context) {
  double percent = total > 0 ? (consumed / total) : 0;
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 2, blurRadius: 10)]),
    
    // Wrap the Column with a SingleChildScrollView to prevent overflow
    child: SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(), // Disables scrolling by user
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 8.0,
            percent: percent > 1.0 ? 1.0 : percent,
            center: Text(consumed.round().toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            progressColor: color,
            backgroundColor: color.withOpacity(0.2),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 14)),
          Text('of ${total.round()} $unit', style: TextStyle(fontSize: 12, color: Colors.grey[500]))
        ],
      ),
    ),
  );
}
}

class _MealCheckCard extends StatelessWidget {
  final Meal meal; final bool isCompleted; final VoidCallback onToggle;
  const _MealCheckCard({required this.meal, required this.isCompleted, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onToggle, borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: isCompleted ? Icon(Icons.check_circle, color: Colors.green, size: 30, key: UniqueKey()) : Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 30, key: UniqueKey()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: isCompleted ? TextDecoration.lineThrough : null, color: isCompleted ? Colors.grey[600] : Colors.black87)),
                    Text('${meal.totalCalories.round()} kcal • ${meal.items.length} items', style: TextStyle(color: Colors.grey[500]))
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealDetailCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onReplace;
  const _MealDetailCard({required this.meal, required this.onReplace});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${meal.totalCalories.round()} kcal'),
        childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
        children: [
          ...meal.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(item.food.name, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 16),
                Text('${item.quantityGrams.round()}g'),
              ],
            ),
          )),
          const Divider(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onReplace,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Replace Meal'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          )
        ],
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  final String notes;
  const _AiInsightCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.red.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.redAccent.withOpacity(0.8)),
            const SizedBox(width: 16),
            Expanded(child: Text(notes, style: const TextStyle(height: 1.5))),
          ],
        ),
      ),
    );
  }
}


class _PlannerSettingsForm extends StatelessWidget {
  final NutritionPreferences preferences;
  const _PlannerSettingsForm({required this.preferences});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NutritionCubit>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Configure Your Plan", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: preferences.dailyBudget.toString(),
            decoration: const InputDecoration(labelText: 'Daily Budget (TND)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => cubit.updatePreferences(preferences.copyWith(dailyBudget: double.tryParse(val) ?? 0)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: preferences.mealsPerDay.toString(),
            decoration: const InputDecoration(labelText: 'Meals per Day', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            onChanged: (val) => cubit.updatePreferences(preferences.copyWith(mealsPerDay: int.tryParse(val) ?? 0)),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: preferences.dietType,
            decoration: const InputDecoration(labelText: 'Diet Focus', border: OutlineInputBorder()),
            items: ['balanced', 'keto'].map((type) => DropdownMenuItem(value: type, child: Text(type.replaceAll('_', ' ').toUpperCase()))).toList(),
            onChanged: (val) => cubit.updatePreferences(preferences.copyWith(dietType: val)),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Vegetarian'),
            value: preferences.isVegetarian,
            onChanged: (val) => cubit.updatePreferences(preferences.copyWith(isVegetarian: val)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final user = (context.read<UserCubit>().state as dynamic).user as UserModel;
              Navigator.pop(context); // Close the bottom sheet
              context.read<NutritionCubit>().generatePlan(user);
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Smart Plan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// --- UTILITY WIDGETS ---

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Center(child: CupertinoActivityIndicator(radius: 18));
  }
}

class _EmptyStateView extends StatelessWidget {
  final VoidCallback onAction; final String actionText;
  const _EmptyStateView({required this.onAction, required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("Welcome to Nutrition AI", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Let's create a personalized meal plan\njust for you.", style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: onAction, icon: const Icon(Icons.arrow_forward), label: Text(actionText)),
        ],
      ),
    );
  }
}

// --- UTILITY FUNCTIONS ---
void _showSettingsSheet(BuildContext context) {
  final cubit = context.read<NutritionCubit>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: BlocBuilder<NutritionCubit, NutritionState>(
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _PlannerSettingsForm(preferences: state.preferences),
          );
        },
      ),
    ),
  );
}
