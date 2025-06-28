import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_cubit.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_state.dart';

import 'package:gloryfit_version_3/models/workout_model.dart';
import 'package:gloryfit_version_3/screens/newWorkoutSystemScreens/live_workout_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutId;
  const WorkoutDetailScreen({Key? key, required this.workoutId}) : super(key: key);

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the details for this specific workout when the screen loads.
    context.read<WorkoutCubit>().loadWorkoutById(widget.workoutId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<WorkoutCubit, WorkoutState>(
        listener: (context, state) {
          // When the cubit says the workout has started, navigate to the live screen.
          if (state is WorkoutInProgress) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<WorkoutCubit>(),
                child:  LiveWorkoutScreen(workout: state.workout,),
              ),
            ));
          } else if (state is WorkoutError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: BlocBuilder<WorkoutCubit, WorkoutState>(
          builder: (context, state) {
            if (state is WorkoutDetailLoaded) {
              return _buildContent(context, state.workout);
            }
            // Show a loading indicator while fetching workout details.
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Workout workout) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildSliverAppBar(workout),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.description, style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.5)),
                    const SizedBox(height: 24),
                    _buildStatsRow(workout),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Exercises', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final exercise = workout.exercises[index];
                  return _buildExerciseTile(exercise, index + 1);
                },
                childCount: workout.exercises.length,
              ),
            ),
            // Add padding at the bottom to avoid being covered by the start button
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        _buildStartButton(context, workout),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar(Workout workout) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.grey[900],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        title: Text(
          workout.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black54)]),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(workout.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black.withOpacity(0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Workout workout) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.timer, '${workout.estimatedDurationMinutes} min', 'Duration'),
          const VerticalDivider(),
          _buildStatItem(Icons.local_fire_department, '${workout.estimatedCaloriesBurn}', 'Calories'),
          const VerticalDivider(),
          _buildStatItem(Icons.bar_chart, workout.difficulty.name, 'Level'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildExerciseTile(WorkoutExercise exercise, int number) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[50],
            child: Text('$number', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('${exercise.sets} sets x ${exercise.repsPerSet} reps', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          Icon(Icons.more_vert, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, Workout workout) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Tell the cubit to start the workout. The BlocListener will handle navigation.
              context.read<WorkoutCubit>().startWorkout(workout.id);
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('START WORKOUT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
      ),
    );
  }
}
