import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FitnessGoalsStep extends StatefulWidget {
  final UserModel user;

  const FitnessGoalsStep({super.key, required this.user});

  @override
  State<FitnessGoalsStep> createState() => _FitnessGoalsStepState();
}

class _FitnessGoalsStepState extends State<FitnessGoalsStep> {
  FitnessGoal? _selectedGoal;

  final Map<FitnessGoal, String> _goalData = {
    FitnessGoal.weightLoss: "https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?fit=crop&w=800&q=80",
    FitnessGoal.muscleGain: "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?fit=crop&w=800&q=80",
    FitnessGoal.endurance: "https://images.unsplash.com/photo-1541696425-1a800a063DB3?fit=crop&w=800&q=80",
    FitnessGoal.generalFitness: "https://images.unsplash.com/photo-1549060279-7e168fcee0c2?fit=crop&w=800&q=80",
  };

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.user.fitnessGoal;
  }

  String _getGoalText(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss: return 'Weight Loss';
      case FitnessGoal.muscleGain: return 'Muscle Gain';
      case FitnessGoal.endurance: return 'Improve Endurance';
      case FitnessGoal.generalFitness: return 'Overall Fitness';
      default: return 'Fitness Goal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            children: [
              Text(
                "What is your primary fitness goal?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "This will help us recommend the best programs for you.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 24),
              itemCount: _goalData.length,
              itemBuilder: (context, index) {
                final goal = _goalData.keys.elementAt(index);
                final imageUrl = _goalData.values.elementAt(index);
                return _GoalCard(
                  title: _getGoalText(goal),
                  imageUrl: imageUrl,
                  isSelected: _selectedGoal == goal,
                  onTap: () => setState(() => _selectedGoal = goal),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedGoal == null
                  ? null
                  : () {
                      context.read<UserCubit>().completeOnboarding(
                            fitnessGoal: _selectedGoal!,
                            trainingDaysPerWeek: 4, // Default or pick from previous step
                          );
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Finish'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.title,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: CachedNetworkImageProvider(imageUrl),
            fit: BoxFit.cover,
          ),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 4,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.6)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
