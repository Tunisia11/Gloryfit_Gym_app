import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/post/post_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_cubit.dart';
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/screens/profile/profile_screen.dart';
import 'package:gloryfit_version_3/services/post_service.dart';
import 'package:gloryfit_version_3/services/storage_service.dart';

Widget buildProfileScreen() {
  return BlocBuilder<UserCubit, UserState>(
    builder: (context, state) {
      UserModel? user;
      if (state is UserLoaded) user = state.user;
      if (state is UserLoadedWithInProgressWorkout) user = state.user;

      if (user != null) {
        // **FIXED**: Provide a new PostCubit instance scoped to the ProfileScreen.
        // This ensures it fetches posts for the correct user.
        return BlocProvider(
          create: (context) => PostCubit(
            PostService(storageService: StorageService()),
         
          ),
          child: ProfileScreen(user: user),
        );
      }

      // Fallback for loading/error states
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    },
  );
}
