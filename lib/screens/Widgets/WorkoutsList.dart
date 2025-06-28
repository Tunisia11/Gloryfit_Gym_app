/*import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/workout/workout_cubit.dart';
import 'package:gloryfit_version_3/cubits/workout/workout_states.dart';
import 'package:gloryfit_version_3/screens/Widgets/WorkoutCard.dart';
import 'package:gloryfit_version_3/screens/workout/workout_detail_screen.dart';
import 'package:gloryfit_version_3/screens/workout/workouts_screen.dart';

/// Widget that displays a list of workouts
/// Used in the dashboard to show available workouts
class WorkoutsList extends StatefulWidget {
  const WorkoutsList({Key? key}) : super(key: key);

  @override
  State<WorkoutsList> createState() => _WorkoutsListState();
}

class _WorkoutsListState extends State<WorkoutsList> {
  @override
  void initState() {
    super.initState();
    // Load workouts when the widget is created
    context.read<WorkoutCubit>().loadWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Workouts Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // "See All" button
              TextButton(
                onPressed: () {
                  // Navigate to all workouts screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WorkoutsScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                ),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.blue[700],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Workouts List
        BlocBuilder<WorkoutCubit, WorkoutState>(
          builder: (context, state) {
            if (state is WorkoutLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (state is WorkoutsLoaded) {
              final workouts = state.workouts;
              
              if (workouts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workouts available yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Show only first 3 workouts in home screen
              final displayWorkouts = workouts.length > 3 
                  ? workouts.sublist(0, 3) 
                  : workouts;
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayWorkouts.length,
                itemBuilder: (context, index) {
                  final workout = displayWorkouts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: WorkoutCard(
                      workout: workout,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => WorkoutDetailScreen(
                              workoutId: workout.id, workout: workout,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            } else if (state is WorkoutError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading workouts',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          context.read<WorkoutCubit>().loadWorkouts();
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Initial or other state
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Loading workouts...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
} */