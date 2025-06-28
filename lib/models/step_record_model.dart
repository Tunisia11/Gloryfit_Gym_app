import 'package:cloud_firestore/cloud_firestore.dart';

class StepRecordModel {
  final DateTime date;
  final int steps;
  final double distance;
  final double caloriesBurned;
  final int goal;
  final bool goalAchieved;

  StepRecordModel({
    required this.date,
    required this.steps,
    required this.distance,
    required this.caloriesBurned,
    required this.goal,
    required this.goalAchieved,
  });

  factory StepRecordModel.fromJson(Map<String, dynamic> json) {
    return StepRecordModel(
      date: (json['date'] as Timestamp).toDate(),
      steps: json['steps'] as int,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      goal: json['goal'] as int,
      goalAchieved: json['goalAchieved'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'steps': steps,
      'distance': distance,
      'caloriesBurned': caloriesBurned,
      'goal': goal,
      'goalAchieved': goalAchieved,
    };
  }

  StepRecordModel copyWith({
    DateTime? date,
    int? steps,
    double? distance,
    double? caloriesBurned,
    int? goal,
    bool? goalAchieved,
  }) {
    return StepRecordModel(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      goal: goal ?? this.goal,
      goalAchieved: goalAchieved ?? this.goalAchieved,
    );
  }
} 