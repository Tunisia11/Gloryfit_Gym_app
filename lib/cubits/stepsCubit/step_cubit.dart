import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:gloryfit_version_3/cubits/stepsCubit/stepStates.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepCubitV2 extends Cubit<StepState> {
  final int _dailyGoal = 10000;
  final double _userWeight;
  final double _userHeight;
  final String _userId;

  StepCubitV2({
    required double userWeight,
    required double userHeight,
    required String userId,
  }) : _userWeight = userWeight,
       _userHeight = userHeight,
       _userId = userId,
       super(const StepInitial()) {
    _initialize();
  }

  void _initialize() async {
    print("userWeight: $_userWeight, userHeight: $_userHeight, userId: $_userId");
    emit(const StepLoading());

    // Tell the background service which user is logged in
    FlutterBackgroundService().invoke('setUserId', {'userId': _userId});

    final prefs = await SharedPreferences.getInstance();
    final steps = prefs.getInt('last_saved_steps') ?? 0;
    
    final calories = _calculateCalories(steps);
   print("userWeight: $_userWeight, userHeight: $_userHeight, userId: $_userId");
    emit(StepLoaded(
      steps,
      _dailyGoal,
      calories: calories,
      date: DateTime.now(),
      pedestrianStatusString: 'Unknown', // Initial status
    ));

    // Listener for step count updates
    FlutterBackgroundService().on('update').listen((event) {
      if (event != null) {
        final newSteps = event['steps'] as int;
        final newCalories = _calculateCalories(newSteps);

        final currentState = state;
        if (currentState is StepLoaded) {
          // Use copyWith to update only the step-related fields
          emit(currentState.copyWith(
            steps: newSteps,
            calories: newCalories,
          ));
        }
      }
    });

    // --- NEW: Listener for Pedestrian Status Updates ---
    FlutterBackgroundService().on('status_update').listen((event) {
      if (event != null) {
        final newStatus = event['status'] as String?;
        final currentState = state;
        if (currentState is StepLoaded) {
          // Use copyWith to update only the status
          emit(currentState.copyWith(pedestrianStatusString: newStatus));
        }
      }
    });
  }

  double _calculateCalories(int steps) {
    return steps * 0.045; // Using a simple multiplier
  }

  @override
  Future<void> close() {
    // Listeners are managed by the service, so we don't need to cancel them here.
    return super.close();
  }
}