import 'package:equatable/equatable.dart';
import 'package:gloryfit_version_3/models/step_record_model.dart';

abstract class StepState extends Equatable {
  const StepState();

  @override
  List<Object?> get props => [];
}

class StepInitial extends StepState {
  const StepInitial();
}

class StepLoading extends StepState {
  const StepLoading();
}

class StepLoaded extends StepState {
  final int steps;
  final int dailyGoal;
  final double calories;
  final DateTime date;
  final String? pedestrianStatusString; // <-- UPDATED

  const StepLoaded(
    this.steps,
    this.dailyGoal, {
    required this.calories,
    required this.date,
    this.pedestrianStatusString, // <-- UPDATED
  });

  double get progress => dailyGoal > 0 ? steps / dailyGoal : 0.0;
  int get remainingSteps => dailyGoal - steps;
  bool get goalAchieved => steps >= dailyGoal;

  @override
  List<Object?> get props => [steps, dailyGoal, calories, date, pedestrianStatusString]; // <-- UPDATED

  StepLoaded copyWith({
    int? steps,
    int? dailyGoal,
    double? calories,
    DateTime? date,
    String? pedestrianStatusString, // <-- UPDATED
  }) {
    return StepLoaded(
      steps ?? this.steps,
      dailyGoal ?? this.dailyGoal,
      calories: calories ?? this.calories,
      date: date ?? this.date,
      pedestrianStatusString: pedestrianStatusString ?? this.pedestrianStatusString, // <-- UPDATED
    );
  }
}

class StepHistoryLoaded extends StepState {
  final List<StepRecordModel> history;

  const StepHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class StepError extends StepState {
  final String message;

  const StepError(this.message);

  @override
  List<Object?> get props => [message];
}