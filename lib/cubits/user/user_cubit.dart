// lib/cubits/user/user_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/auth/auth_cubit.dart';
import 'package:gloryfit_version_3/cubits/auth/auth_states.dart' as auth_states;
import 'package:gloryfit_version_3/cubits/user/user_states.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/service/user_service.dart';
import 'package:gloryfit_version_3/service/workout_service.dart';

class UserCubit extends Cubit<UserState> {
  final UserService _userService;
  final WorkoutService _workoutService;
  final AuthCubit _authCubit;
  late final StreamSubscription _authSubscription;

  UserCubit(this._userService, this._workoutService, this._authCubit)
      : super(const UserInitial()) {
    _authSubscription = _authCubit.stream.listen(_onAuthStateChanged);
    _onAuthStateChanged(_authCubit.state);
  }

  void _onAuthStateChanged(auth_states.AuthState authState) {
    if (isClosed) return;
    if (authState is auth_states.AuthAuthenticated) {
      final currentState = state;
      // Avoid reloading data if the user is already loaded.
      if (currentState is UserLoaded && currentState.user.id == authState.userId) return;
      
      final fallbackUser = UserModel(
        id: authState.userId,
        email: authState.email ?? '',
        displayName: authState.displayName,
        photoURL: authState.photoURL,
        isOnboardingCompleted: false,
        createdAt: DateTime.now(),
      );
      loadUser(authState.userId, fallbackUserData: fallbackUser);
    } else if (authState is auth_states.AuthUnauthenticated) {
      resetUserState();
    }
  }

  Future<void> loadUser(String userId, {required UserModel fallbackUserData}) async {
    try {
      if (state is UserLoading) return;
      emit(const UserLoading());
      final user = await _userService.getUserById(userId);

      if (user != null) {
        if (user.isOnboardingCompleted) {
          // **FIX**: Check for an in-progress workout after loading the user.
          final inProgressWorkout = await _workoutService.getInProgressWorkout();
          if (inProgressWorkout != null) {
            final workoutDetails = await _workoutService.getWorkoutById(inProgressWorkout.workoutId);
            if (workoutDetails != null) {
              // If a workout is in progress, emit the specific state for it.
              emit(UserLoadedWithInProgressWorkout(user: user, workout: workoutDetails, progress: inProgressWorkout));
            } else {
              // Fallback to normal loaded state if workout details fail to load.
              emit(UserLoaded(user));
            }
          } else {
            // No workout in progress, load normally.
            emit(UserLoaded(user));
          }
        } else {
          emit(OnboardingInProgress(currentStep: 0, user: user));
        }
      } else {
        await _createUser(fallbackUserData);
      }
    } catch (e) {
      emit(UserError("Failed to load user data: ${e.toString()}"));
    }
  }

  Future<void> _createUser(UserModel user) async {
    try {
      final isAdmin = user.email.toLowerCase().contains('admin');
      final newUser = user.copyWith(
        role: isAdmin ? UserRole.admin : UserRole.member,
        createdAt: DateTime.now(),
        isOnboardingCompleted: false,
      );
      await _userService.createOrUpdateUser(newUser);
      if (isAdmin) {
        await _userService.updateOnboardingStatus(newUser.id, true);
        emit(UserLoaded(newUser.copyWith(isOnboardingCompleted: true)));
      } else {
        emit(OnboardingInProgress(currentStep: 0, user: newUser));
      }
    } catch (e) {
      emit(UserError("Failed to create user: ${e.toString()}"));
    }
  }

  void setOnboardingStep(int step, {DateTime? dateOfBirth, Gender? gender, double? height, double? weight}) {
    final currentState = state;
    if (currentState is OnboardingInProgress) {
      final updatedUser = currentState.user.copyWith(
        dateOfBirth: dateOfBirth,
        gender: gender,
        height: height,
        weight: weight,
      );
      emit(OnboardingInProgress(currentStep: step, user: updatedUser));
    }
  }

  Future<void> completeOnboarding({required FitnessGoal fitnessGoal, required int trainingDaysPerWeek}) async {
    final currentState = state;
    if (currentState is OnboardingInProgress) {
      emit(const UserLoading());
      try {
        final userToComplete = currentState.user.copyWith(
          fitnessGoal: fitnessGoal,
          trainingDaysPerWeek: trainingDaysPerWeek,
          isOnboardingCompleted: true,
        );
        await _userService.createOrUpdateUser(userToComplete);
        emit(UserLoaded(userToComplete));
      } catch (e) {
        emit(UserError("Failed to complete onboarding: ${e.toString()}"));
      }
    }
  }

  void resetUserState() {
    emit(const UserInitial());
  }

  @override
  void emit(UserState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
