// lib/cubits/user/user_states.dart
import 'package:equatable/equatable.dart';
import 'package:gloryfit_version_3/models/user_model.dart';
import 'package:gloryfit_version_3/models/workout_model.dart';
import 'package:gloryfit_version_3/models/workout_progress_model.dart';

abstract class UserState extends Equatable {
  const UserState();
   @override
  List<Object> get props => [];
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UserLoaded extends UserState {
  final UserModel user;
  const UserLoaded(this.user);
   @override
  List<Object> get props => [user];
}

class UserError extends UserState {
  final String message;
  const UserError(this.message);
   @override
  List<Object> get props => [message];
}

class OnboardingInProgress extends UserState {
  final int currentStep;
  final UserModel user;
  const OnboardingInProgress({
    required this.currentStep,
    required this.user,
  });
   @override
  List<Object> get props => [currentStep, user];
}

class OnboardingCompleted extends UserState {
  final UserModel user;
  const OnboardingCompleted(this.user);
   @override
  List<Object> get props => [user];
} 

// **FIX**: Added Equatable for proper state comparison.
class UserLoadedWithInProgressWorkout extends UserState {
  final UserModel user;
  final Workout workout;
  final WorkoutProgress progress;
  
  const UserLoadedWithInProgressWorkout({
    required this.user,
    required this.workout,
    required this.progress,
  });

  @override
  List<Object> get props => [user, workout, progress];
}
