// lib/cubits/new_Workout_system/workout_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloryfit_version_3/cubits/new_Workout_system/workout_state.dart';
import 'package:gloryfit_version_3/models/workout_model.dart';
import 'package:gloryfit_version_3/models/workout_progress_model.dart';
import 'package:gloryfit_version_3/service/workout_service.dart';

/// The central controller for the entire workout experience.
/// This cubit manages the state and logic for a live workout session.
/// **FIXED**: This cubit no longer uses timers to emit states every second.
class WorkoutCubit extends Cubit<WorkoutState> {
  final WorkoutService _workoutService;

  Workout? _activeWorkout;
  WorkoutProgress? _activeWorkoutProgress;
  Timer? _restTimer;

  WorkoutCubit(this._workoutService) : super(WorkoutInitial());

  Future<void> loadWorkouts() async {
    try {
      emit(WorkoutLoading());
      final workouts = await _workoutService.getAllWorkouts();
      emit(WorkoutsListLoaded(workouts));
    } catch (e) {
      emit(WorkoutError(e.toString()));
    }
  }

  Future<void> loadWorkoutById(String workoutId) async {
    try {
      emit(WorkoutLoading());
      final workout = await _workoutService.getWorkoutById(workoutId);
      if (workout != null) {
        emit(WorkoutDetailLoaded(workout));
      } else {
        emit(const WorkoutError('Workout not found'));
      }
    } catch (e) {
      emit(WorkoutError(e.toString()));
    }
  }

  Future<void> startWorkout(String workoutId) async {
    try {
      emit(WorkoutLoading());
      final workout = await _workoutService.getWorkoutById(workoutId);
      if (workout == null) {
        emit(const WorkoutError('Workout not found'));
        return;
      }
      
      final progress = await _workoutService.startWorkout(workoutId);
      if (progress != null) {
        _activeWorkout = workout;
        _activeWorkoutProgress = progress;
        emit(WorkoutInProgress(
          workout: _activeWorkout!,
          progress: _activeWorkoutProgress!,
          // The total time is calculated from the start time.
          totalTimeInSeconds: DateTime.now().difference(progress.startedAt).inSeconds,
        ));
      } else {
        emit(const WorkoutError('Failed to start workout'));
      }
    } catch (e) {
      emit(WorkoutError(e.toString()));
    }
  }

  /// **FIX**: Logic to resume a workout that was already in progress.
  void resumeExistingWorkout(Workout workout, WorkoutProgress progress) {
    _activeWorkout = workout;
    _activeWorkoutProgress = progress;
    emit(WorkoutInProgress(
      workout: workout,
      progress: progress,
      totalTimeInSeconds: DateTime.now().difference(progress.startedAt).inSeconds,
    ));
  }

  void completeSet() {
    if (_activeWorkout == null || _activeWorkoutProgress == null) return;

    final progress = _activeWorkoutProgress!;
    final exerciseIndex = progress.exercises.indexWhere((e) => !e.isCompleted);
    if (exerciseIndex == -1) {
      completeWorkout();
      return;
    }
    
    final exerciseProgress = progress.exercises[exerciseIndex];
    final setIndex = exerciseProgress.sets.indexWhere((s) => !s.isCompleted);
    
    if (setIndex != -1) {
      final updatedSets = List<SetProgress>.from(exerciseProgress.sets);
      updatedSets[setIndex] = updatedSets[setIndex].copyWith(isCompleted: true);
      
      final isExerciseComplete = (setIndex + 1) == updatedSets.length;
      final updatedExerciseProgress = exerciseProgress.copyWith(
        sets: updatedSets,
        isCompleted: isExerciseComplete,
        completedAt: isExerciseComplete ? DateTime.now() : null,
      );

      final updatedExercises = List<ExerciseProgress>.from(progress.exercises);
      updatedExercises[exerciseIndex] = updatedExerciseProgress;
      
      _activeWorkoutProgress = progress.copyWith(exercises: updatedExercises);
      _workoutService.updateWorkoutProgress(_activeWorkoutProgress!);

      final isWorkoutComplete = isExerciseComplete && (exerciseIndex + 1) == _activeWorkout!.exercises.length;
      if (isWorkoutComplete) {
        completeWorkout();
      } else {
        final restDuration = _activeWorkout!.exercises[exerciseIndex].restBetweenSetsSeconds;
        _startRestTimer(restDuration);
      }
    }
  }
  
  void skipRest() {
    _restTimer?.cancel();
    resumeWorkout();
  }

  Future<void> completeWorkout() async {
    _restTimer?.cancel();
    if (_activeWorkoutProgress == null || _activeWorkout == null) return;

    final duration = DateTime.now().difference(_activeWorkoutProgress!.startedAt).inMinutes;
    final finalProgress = _activeWorkoutProgress!.copyWith(
      status: WorkoutStatus.completed,
      completedAt: DateTime.now(),
      completionPercentage: 100,
      durationMinutes: duration,
    );
    await _workoutService.updateWorkoutProgress(finalProgress);
    
    emit(WorkoutCompleted(workout: _activeWorkout!, progress: finalProgress));
    _resetActiveWorkoutState();
  }

  void pauseWorkout() {
    _restTimer?.cancel();
    emit(WorkoutPaused(
        workout: _activeWorkout!,
        progress: _activeWorkoutProgress!,
        totalTimeInSeconds: DateTime.now().difference(_activeWorkoutProgress!.startedAt).inSeconds
    ));
  }

  void resumeWorkout() {
    emit(WorkoutInProgress(
        workout: _activeWorkout!,
        progress: _activeWorkoutProgress!,
        totalTimeInSeconds: DateTime.now().difference(_activeWorkoutProgress!.startedAt).inSeconds
    ));
  }

  /// **FIX**: The rest timer now only emits a state ONCE. It uses a Future to
  /// transition to the next state automatically after the duration.
  void _startRestTimer(int duration) {
    _restTimer?.cancel();
    int restTime = duration > 0 ? duration : 30;

    emit(WorkoutResting(
      workout: _activeWorkout!,
      progress: _activeWorkoutProgress!,
      restTimeRemaining: restTime,
      totalTimeInSeconds: DateTime.now().difference(_activeWorkoutProgress!.startedAt).inSeconds,
    ));

    // After the rest duration, automatically resume the workout.
    _restTimer = Timer(Duration(seconds: restTime), () {
      if (state is WorkoutResting) {
         resumeWorkout();
      }
    });
  }

  void _resetActiveWorkoutState() {
    _restTimer?.cancel();
    _activeWorkout = null;
    _activeWorkoutProgress = null;
  }

  @override
  Future<void> close() {
    _restTimer?.cancel();
    return super.close();
  }
}
