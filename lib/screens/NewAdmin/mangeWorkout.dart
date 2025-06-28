// lib/screens/admin/manage_workouts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_cubit.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_state.dart';
import 'package:gloryfit_version_3/models/workout_model.dart';
import 'package:gloryfit_version_3/screens/NewAdmin/workout_form_screen.dart';


/// A screen for administrators to view, create, edit, and delete workouts.
class ManageWorkoutsScreen extends StatefulWidget {
  const ManageWorkoutsScreen({Key? key}) : super(key: key);

  @override
  State<ManageWorkoutsScreen> createState() => _ManageWorkoutsScreenState();
}

class _ManageWorkoutsScreenState extends State<ManageWorkoutsScreen> {
  @override
  void initState() {
    super.initState();
    // Load workouts when the screen initializes.
    context.read<WorkoutCubit>().loadWorkouts();
  }

  /// Navigates to the WorkoutFormScreen and refreshes the list upon return.
  void _navigateAndRefresh(BuildContext context, {Workout? workout}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<WorkoutCubit>(),
          // Pass existing workout for editing, or null for creation.
          child: WorkoutFormScreen(workout: workout),
        ),
      ),
    );
    // Refresh the list to show any changes.
    context.read<WorkoutCubit>().loadWorkouts();
  }
  
  // TODO: Implement delete confirmation and logic.
  void _confirmDelete(BuildContext context, Workout workout) {
     // Placeholder for delete functionality
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete for "${workout.name}" is not yet implemented.'), backgroundColor: Colors.orange),
      );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Workouts'),
         actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<WorkoutCubit>().loadWorkouts(),
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: BlocConsumer<WorkoutCubit, WorkoutState>(
        listener: (context, state) {
          if (state is WorkoutError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is WorkoutsListLoaded) {
            if (state.workouts.isEmpty) {
              return const Center(child: Text('No workouts found. Create one!'));
            }
            return ListView.builder(
              itemCount: state.workouts.length,
              itemBuilder: (context, index) {
                final workout = state.workouts[index];
                return Card(
                   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: workout.imageUrl.isNotEmpty
                      ? Image.network(workout.imageUrl, width: 56, height: 56, fit: BoxFit.cover)
                      : const Icon(Icons.fitness_center, size: 40, color: Colors.grey),
                    title: Text(workout.name),
                    subtitle: Text('${workout.exercises.length} exercises - ${workout.difficulty.name}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _navigateAndRefresh(context, workout: workout),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, workout),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          // Default to a loading indicator for other states.
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateAndRefresh(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Workout'),
      ),
    );
  }
}
