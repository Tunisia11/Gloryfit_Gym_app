import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/auth/auth_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/models/workout_model.dart';
import 'package:gloryfit_version_3/models/workout_progress_model.dart';
import 'package:gloryfit_version_3/screens/dashbord/screen/dashbord.dart';
import 'package:gloryfit_version_3/screens/dashbord/screen/homeDashbord.dart';

/// Screen shown after a workout is successfully completed.
/// Displays a summary of stats, congratulations message, and a confetti effect.
class WorkoutSummaryScreen extends StatefulWidget {
  final Workout workout;
  final WorkoutProgress progress;

  const WorkoutSummaryScreen({
    Key? key,
    required this.workout,
    required this.progress,
  }) : super(key: key);

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // Play the confetti animation as soon as the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Main content
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildSummaryDetails(),
              ),
              _buildDoneButton(context),
            ],
          ),
          // Confetti celebration effect
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the top header section with a congratulations message.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events, size: 72, color: Colors.yellow[600]),
          const SizedBox(height: 16),
          const Text(
            'WORKOUT COMPLETED!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Great job on finishing the ${widget.workout.name} workout.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Builds the main body with all the workout statistics.
  Widget _buildSummaryDetails() {
    final progress = widget.progress;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // A grid of key stats for a visually appealing summary.
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                icon: Icons.timer,
                value: '${progress.durationMinutes} min',
                label: 'Duration',
              ),
              _buildStatCard(
                icon: Icons.local_fire_department,
                // Using estimated calories for now. This can be calculated more accurately.
                value: '${widget.workout.estimatedCaloriesBurn} kcal',
                label: 'Calories Burned',
              ),
              _buildStatCard(
                icon: Icons.fitness_center,
                value: '${progress.exercises.length}',
                label: 'Exercises',
              ),
              _buildStatCard(
                icon: Icons.check_circle_outline,
                value: '${progress.completionPercentage.toInt()}%',
                label: 'Completion',
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildFitnessTipCard(),
        ],
      ),
    );
  }

  /// A card for displaying a single statistic.
  Widget _buildStatCard({required IconData icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue[700], size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// A card displaying a helpful tip for post-workout recovery.
  Widget _buildFitnessTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.blue[800], size: 32),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'For optimal recovery, make sure to hydrate well and have a protein-rich meal.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
Widget _buildDoneButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // --- FIX: Safely get the user from the UserCubit state ---
            final userState = context.read<UserCubit>().state;
            if (userState is UserLoaded) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => Dashbord(user: userState.user)), (route) => false);
            } else if (userState is UserLoadedWithInProgressWorkout) {
                 Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => Dashbord(user: userState.user)), (route) => false);
            } else {
              // Fallback if user state is not loaded, just pop until the first screen
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          child: const Text('DONE'),
        ),
      ),
    );
  }
}