import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_cubit.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_state.dart';
import 'package:gloryfit_version_3/cubits/story/cubit.dart' show StoryCubit;
import 'package:gloryfit_version_3/cubits/story/states.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/models/workout_model.dart';
import 'package:gloryfit_version_3/models/workout_progress_model.dart';
import 'package:gloryfit_version_3/screens/dashbord/widgets/ProfileScreenWidget.dart';
import 'package:gloryfit_version_3/screens/dashbord/widgets/StepCounting.dart';
import 'package:gloryfit_version_3/screens/dashbord/widgets/community_highlights.dart';
// **ADDED**: Import the new class slider widget
import 'package:gloryfit_version_3/screens/dashbord/widgets/class_highlights_slider.dart';
import 'package:gloryfit_version_3/screens/dashbord/widgets/openHoursWidget.dart';
import 'package:gloryfit_version_3/screens/dashbord/widgets/placeholderWorkout.dart';
import 'package:gloryfit_version_3/screens/newWorkoutSystemScreens/live_workout_screen.dart';
import 'package:gloryfit_version_3/screens/posts/widgets/storybar.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;
  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkoutCubit, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutInProgress) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<WorkoutCubit>(),
              child: LiveWorkoutScreen(workout: state.workout),
            ),
          ));
        }
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            _buildHeader(context, user),
            const SizedBox(height: 20),
            BlocBuilder<StoryCubit, StoryState>(
              builder: (context, state) {
                if (state is StoriesLoaded && state.stories.isNotEmpty) {
                  return StoryBar(groupedStories: state.groupedStories);
                }
                return const SizedBox.shrink();
              },
            ),
              BlocBuilder<UserCubit, UserState>(
              builder: (context, userState) {
                if (userState is UserLoadedWithInProgressWorkout) {
                  return _buildInProgressWorkoutCard(
                      context, userState.workout, userState.progress);
                } else {
                  return _buildFeaturedWorkoutSection();
                }
              },
            ),
            const SizedBox(height: 30),
            // **ADDED**: The new Class Highlights slider
            const ClassHighlightsSlider(),
           
          
            const SizedBox(height: 30),
            !kIsWeb ? StepProgressWidget() : const SizedBox.shrink(),
            const SizedBox(height: 20),
            const CommunityHighlights(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.displayName?.split(' ').first ?? 'User',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                  const OpeningHoursStatus(),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => buildProfileScreen(),
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                  ? NetworkImage(user.photoURL!)
                  : null,
              backgroundColor: Colors.grey[200],
              child: user.photoURL == null || user.photoURL!.isEmpty
                  ? Text(
                      user.displayName?[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedWorkoutSection() {
    return BlocBuilder<WorkoutCubit, WorkoutState>(
      buildWhen: (previous, current) => current is WorkoutsListLoaded,
      builder: (context, state) {
        if (state is WorkoutsListLoaded) {
          if (state.workouts.isNotEmpty) {
            final featuredWorkout = state.workouts.first;
            return _buildStartNewWorkoutCard(context, featuredWorkout);
          } else {
            return const PlaceholderWorkouts();
          }
        }
        return const PlaceholderWorkouts();
      },
    );
  }

  Widget _buildStartNewWorkoutCard(BuildContext context, Workout workout) {
    return _buildWorkoutCard(
      context: context,
      workout: workout,
      buttonText: "START WORKOUT",
      buttonIcon: Icons.play_arrow,
      onTap: () {
        context.read<WorkoutCubit>().startWorkout(workout.id);
      },
    );
  }

  Widget _buildInProgressWorkoutCard(
      BuildContext context, Workout workout, WorkoutProgress progress) {
    return _buildWorkoutCard(
      context: context,
      workout: workout,
      progress: progress,
      buttonText: "CONTINUE WORKOUT",
      buttonIcon: Icons.play_arrow,
     // In your Dashbord.dart file, inside the resume button's onPressed:
onTap: () {
  final userState = context.read<UserCubit>().state;
  if (userState is UserLoadedWithInProgressWorkout) {
    // This is the crucial first step:
    // Tell the WorkoutCubit to resume the session with the existing data.
    context.read<WorkoutCubit>().resumeExistingWorkout(
      userState.workout,
      userState.progress,
    );

    // NOW, navigate to the live screen.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<WorkoutCubit>(),
        child: LiveWorkoutScreen(workout: userState.workout),
      ),
    ));
  }
}
    );
  }

  Widget _buildWorkoutCard({
    required BuildContext context,
    required Workout workout,
    WorkoutProgress? progress,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback onTap,
  }) {
    final double completionValue = progress?.completionPercentage ?? 0.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
            image: NetworkImage(workout.imageUrl), fit: BoxFit.cover),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(workout.difficulty.name.toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  Text("${workout.estimatedDurationMinutes} min",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                      child: Text(workout.name,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white))),
                  if (progress != null)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: completionValue / 100,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        ),
                        Text("${completionValue.toInt()}%",
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    )
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: Icon(buttonIcon, size: 20),
                  label: Text(buttonText),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
