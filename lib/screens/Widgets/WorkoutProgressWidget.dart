/*import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_cubit.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_state.dart';

import 'package:gloryfit_version_3/models/workout_progress_model.dart';
import 'package:intl/intl.dart';

/// A widget that displays user's workout progress statistics on the dashboard
class WorkoutProgressWidget extends StatefulWidget {
  const WorkoutProgressWidget({Key? key, required List<dynamic> workouts}) : super(key: key);

  @override
  State<WorkoutProgressWidget> createState() => _WorkoutProgressWidgetState();
}

class _WorkoutProgressWidgetState extends State<WorkoutProgressWidget> {
  @override
  void initState() {
    super.initState();
    // Load workout history when widget is created
    context.read<WorkoutCubit>().loadWorkoutHistory();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutCubit, WorkoutState>(
      builder: (context, state) {
        if (state is WorkoutLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is WorkoutHistoryLoaded) {
          // Show workout progress when history is loaded
          return _buildProgressContent(state.history);
        } else {
          // Show placeholder when no data is available
          return _buildEmptyState();
        }
      },
    );
  }

  /// Build the main progress content with stats
  Widget _buildProgressContent(List<WorkoutProgress> history) {
    // If no workout history exists, show empty state
    if (history.isEmpty) {
      return _buildEmptyState();
    }

    // Calculate statistics
    final completedWorkouts = history.length;
    final lastWorkout = history.first; // Already sorted by date in the cubit
    final totalMinutes = _calculateTotalMinutes(history);
    
    // Get last workout date
    final lastWorkoutDate = lastWorkout.completedAt ?? lastWorkout.startedAt;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade700, Colors.blue.shade900],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  context.read<WorkoutCubit>().loadWorkoutHistory();
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Workout statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.fitness_center,
                value: '$completedWorkouts',
                label: 'Workouts',
              ),
              _buildStatItem(
                icon: Icons.timer,
                value: '$totalMinutes',
                label: 'Minutes',
              ),
              _buildStatItem(
                icon: Icons.calendar_today,
                value: _formatDate(lastWorkoutDate),
                label: 'Last Workout',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Recent activity
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Recent workouts list
          SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: history.length > 3 ? 3 : history.length,
              itemBuilder: (context, index) {
                final workout = history[index];
                return _buildRecentWorkoutItem(workout);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build an empty state when no workout history exists
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade200, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            'No Workout History Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Complete a workout to see your progress here!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build a single stat item
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  /// Build a recent workout item
  Widget _buildRecentWorkoutItem(WorkoutProgress workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fitness_center,
            color: Colors.white.withOpacity(0.8),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.workoutId ?? 'Workout',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _formatDateTime(workout.completedAt ?? workout.startedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(workout.durationMinutes).round()} min',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate total minutes across all workouts
  int _calculateTotalMinutes(List<WorkoutProgress> history) {
    return history.fold(0, (sum, workout) => sum + workout.durationMinutes.round());
  }

  /// Format date to a readable string
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  /// Format date and time to a readable string
  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, h:mm a').format(date);
  }
} */