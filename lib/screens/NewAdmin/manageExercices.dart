// lib/screens/admin/manage_exercises_screen.dart
import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/models/exercise_model.dart';
import 'package:gloryfit_version_3/screens/NewAdmin/exercise_form_screen.dart';
import 'package:gloryfit_version_3/service/exercise_service.dart';


/// A screen for administrators to view, create, and delete exercises.
/// This screen acts as the main hub for the exercise library.
class ManageExercisesScreen extends StatefulWidget {
  const ManageExercisesScreen({super.key});

  @override
  State<ManageExercisesScreen> createState() => _ManageExercisesScreenState();
}

class _ManageExercisesScreenState extends State<ManageExercisesScreen> {
  // A future to hold the list of exercises fetched from the service.
  late Future<List<Exercise>> _exercisesFuture;
  final ExerciseService _exerciseService = ExerciseService();

  @override
  void initState() {
    super.initState();
    // Initial load of exercises when the screen is first built.
    _loadExercises();
  }

  /// Refreshes the list of exercises from the ExerciseService.
  void _loadExercises() {
    setState(() {
      _exercisesFuture = _exerciseService.getAllExercises();
    });
  }

  /// Navigates to the ExerciseFormScreen and refreshes the list upon return.
  void _navigateAndRefresh(BuildContext context) async {
    // Wait for the ExerciseFormScreen to pop before refreshing.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExerciseFormScreen()),
    );
    // Refresh the list to show any newly created exercises.
    _loadExercises();
  }

  /// Shows a confirmation dialog before deleting an exercise.
  Future<void> _confirmDelete(BuildContext context, Exercise exercise) async {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete "${exercise.name}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                try {
                  await _exerciseService.deleteExercise(exercise.id);
                  Navigator.of(ctx).pop(); // Close the dialog
                  _loadExercises(); // Refresh the list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${exercise.name}" deleted successfully.'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting exercise: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Exercises'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExercises,
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: FutureBuilder<List<Exercise>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          // Show a loading indicator while data is being fetched.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Show an error message if fetching failed.
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          // Show a message if there are no exercises.
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No exercises found. Add one to get started!'));
          }

          final exercises = snapshot.data!;
          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty
                      ? Image.network(exercise.imageUrl!, width: 56, height: 56, fit: BoxFit.cover)
                      : const Icon(Icons.video_library, size: 40, color: Colors.grey),
                  title: Text(exercise.name),
                  subtitle: Text(
                    exercise.targetMuscles.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, exercise),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateAndRefresh(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
      ),
    );
  }
}
