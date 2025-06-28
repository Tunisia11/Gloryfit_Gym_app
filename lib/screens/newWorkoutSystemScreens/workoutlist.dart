import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_cubit.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_state.dart';

import 'package:gloryfit_version_3/models/workout_model.dart';
import 'package:gloryfit_version_3/screens/newWorkoutSystemScreens/workout_detail_screen.dart';


class WorkoutsListScreen extends StatefulWidget {
  const WorkoutsListScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutsListScreen> createState() => _WorkoutsListScreenState();
}

class _WorkoutsListScreenState extends State<WorkoutsListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the list of workouts when the screen is first initialized.
    // Check the state first to avoid unnecessary reloads if data is already present.
    if (context.read<WorkoutCubit>().state is! WorkoutsListLoaded) {
      context.read<WorkoutCubit>().loadWorkouts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Workout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: BlocBuilder<WorkoutCubit, WorkoutState>(
        builder: (context, state) {
          if (state is WorkoutLoading && state is! WorkoutsListLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WorkoutsListLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<WorkoutCubit>().loadWorkouts();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: state.workouts.length,
                itemBuilder: (context, index) {
                  final workout = state.workouts[index];
                  return _buildWorkoutCard(context, workout);
                },
              ),
            );
          }
          if (state is WorkoutError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          // Default state or if something unexpected happens
          return const Center(child: Text('No workouts available. Pull to refresh.'));
        },
      ),
    );
  }

  /// Builds a visually appealing card for a single workout.
  Widget _buildWorkoutCard(BuildContext context, Workout workout) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<WorkoutCubit>(),
            child: WorkoutDetailScreen(workoutId: workout.id ,),
          ),
        ));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Gradient Overlay
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.network(
                  workout.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    workout.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            // Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatChip(Icons.timer, '${workout.estimatedDurationMinutes} min'),
                  _buildStatChip(Icons.local_fire_department, '${workout.estimatedCaloriesBurn} kcal'),
                  _buildDifficultyBadge(workout.difficulty),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A small chip to display workout stats like duration or calories.
  Widget _buildStatChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 18),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
      ],
    );
  }

  /// A colored badge to indicate the workout's difficulty level.
  Widget _buildDifficultyBadge(WorkoutDifficulty difficulty) {
    final Map<WorkoutDifficulty, dynamic> difficultyInfo = {
      WorkoutDifficulty.beginner: {'text': 'Beginner', 'color': Colors.green},
      WorkoutDifficulty.intermediate: {'text': 'Intermediate', 'color': Colors.orange},
      WorkoutDifficulty.advanced: {'text': 'Advanced', 'color': Colors.red},
      WorkoutDifficulty.expert: {'text': 'Expert', 'color': Colors.purple},
    };

    final info = difficultyInfo[difficulty] ?? {'text': 'Unknown', 'color': Colors.grey};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: info['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        info['text'].toUpperCase(),
        style: TextStyle(
          color: info['color'],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
