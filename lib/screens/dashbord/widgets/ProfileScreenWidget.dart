import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/screens/NewAdmin/Dashbord.dart';

import 'package:gloryfit_version_3/screens/profile/profile_screen.dart';

Widget buildProfileScreen() {
  return BlocBuilder<UserCubit, UserState>(
    builder: (context, state) {
      // First, try to extract the user model from any state that holds it.
      UserModel? user;
      if (state is UserLoaded) {
        user = state.user;
      } else if (state is UserLoadedWithInProgressWorkout) {
        user = state.user;
      } else if (state is OnboardingCompleted) {
        user = state.user;
      } else if (state is OnboardingInProgress) {
        user = state.user;
      }

      // If we have a user, build the profile screen.
      if (user != null) {
        return ProfileScreen(
          user: user,
        
        );
      }

      // Handle loading, error, and unauthenticated states.
      if (state is UserLoading || state is UserInitial) {
        return const Center(child: CircularProgressIndicator());
      } else if (state is UserError) {
        return Center(child: Text('Error: ${state.message}'));
      } else {
        // Fallback for any other unhandled state.
        return const Center(child: Text('Please login'));
      }
    },
  );
}