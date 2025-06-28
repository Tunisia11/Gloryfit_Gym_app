// lib/cubits/new_Workout_system/workout_state.dart
import 'package:equatable/equatable.dart';
import 'package:gloryfit_version_3/models/workout_model.dart';
import 'package:gloryfit_version_3/models/workout_progress_model.dart';

/// **FIX**: This abstract class is crucial. It creates a "contract"
/// that any state with a timer must follow, allowing the UI to safely
/// access 'totalTimeInSeconds'.
abstract class WorkoutStateWithTime {
  int get totalTimeInSeconds;
}

abstract class WorkoutState extends Equatable {
  const WorkoutState();
  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {}

class WorkoutLoading extends WorkoutState {}

class WorkoutsListLoaded extends WorkoutState {
  final List<Workout> workouts;
  const WorkoutsListLoaded(this.workouts);
  @override
  List<Object> get props => [workouts];
}

class WorkoutDetailLoaded extends WorkoutState {
  final Workout workout;
  const WorkoutDetailLoaded(this.workout);
  @override
  List<Object> get props => [workout];
}

// **FIX**: Implements the abstract class for consistent time access.
class WorkoutInProgress extends WorkoutState implements WorkoutStateWithTime {
  final Workout workout;
  final WorkoutProgress progress;
  @override
  final int totalTimeInSeconds;

  const WorkoutInProgress({required this.workout, required this.progress, required this.totalTimeInSeconds});
  @override
  List<Object> get props => [workout, progress, totalTimeInSeconds];
}

// **FIX**: Implements the abstract class.
class WorkoutPaused extends WorkoutState implements WorkoutStateWithTime {
  final Workout workout;
  final WorkoutProgress progress;
  @override
  final int totalTimeInSeconds;

  const WorkoutPaused({required this.workout, required this.progress, required this.totalTimeInSeconds});
  @override
  List<Object> get props => [workout, progress, totalTimeInSeconds];
}

// **FIX**: Implements the abstract class.
class WorkoutResting extends WorkoutState implements WorkoutStateWithTime {
  final Workout workout;
  final WorkoutProgress progress;
  final int restTimeRemaining;
  @override
  final int totalTimeInSeconds;
  
  const WorkoutResting({required this.workout, required this.progress, required this.restTimeRemaining, required this.totalTimeInSeconds});
  @override
  List<Object> get props => [workout, progress, restTimeRemaining, totalTimeInSeconds];
}

class WorkoutCompleted extends WorkoutState {
  final Workout workout;
  final WorkoutProgress progress;
  const WorkoutCompleted({required this.workout, required this.progress});
  @override
  List<Object> get props => [workout, progress];
}

class WorkoutError extends WorkoutState {
  final String message;
  const WorkoutError(this.message);
  @override
  List<Object> get props => [message];
}
