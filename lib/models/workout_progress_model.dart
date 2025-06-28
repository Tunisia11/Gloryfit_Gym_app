import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's workout session and progress
/// Used to track history and completion of workouts
class WorkoutProgress {
  final String id;               // Unique identifier
  final String userId;           // User who performed the workout
  final String workoutId;        // Reference to the workout
  final DateTime startedAt;      // When the workout began
  final DateTime? completedAt;   // When workout was completed (null if not finished)
  final WorkoutStatus status;    // Current status
  final List<ExerciseProgress> exercises; // Progress on each exercise
  final double completionPercentage; // Overall completion percentage
  final int caloriesBurned;      // Estimated calories burned
  final int durationMinutes;     // Total minutes spent
  
  WorkoutProgress({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.startedAt,
    this.completedAt,
    required this.status,
    required this.exercises,
    required this.completionPercentage,
    required this.caloriesBurned,
    required this.durationMinutes,
  });

  /// Create from Firestore document
  factory WorkoutProgress.fromFirestore(DocumentSnapshot doc, {List<ExerciseProgress>? exercises}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse timestamps
    Timestamp startTimestamp = data['startedAt'] as Timestamp? ?? Timestamp.now();
    Timestamp? completeTimestamp = data['completedAt'] as Timestamp?;
    
    return WorkoutProgress(
      id: doc.id,
      userId: data['userId'] ?? '',
      workoutId: data['workoutId'] ?? '',
      startedAt: startTimestamp.toDate(),
      completedAt: completeTimestamp?.toDate(),
      status: _parseWorkoutStatus(data['status']),
      exercises: exercises ?? [],
      completionPercentage: (data['completionPercentage'] ?? 0).toDouble(),
      caloriesBurned: data['caloriesBurned'] ?? 0,
      durationMinutes: data['durationMinutes'] ?? 0,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'workoutId': workoutId,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status.toString().split('.').last,
      'completionPercentage': completionPercentage,
      'caloriesBurned': caloriesBurned,
      'durationMinutes': durationMinutes,
      'exerciseCount': exercises.length,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Helper to parse workout status from string
  static WorkoutStatus _parseWorkoutStatus(String? value) {
    if (value == null) return WorkoutStatus.inProgress;
    
    try {
      return WorkoutStatus.values.firstWhere(
        (status) => status.toString().split('.').last == value,
      );
    } catch (_) {
      return WorkoutStatus.inProgress;
    }
  }

  /// Create a copy with modified fields
  WorkoutProgress copyWith({
    String? id,
    String? userId,
    String? workoutId,
    DateTime? startedAt,
    DateTime? completedAt,
    WorkoutStatus? status,
    List<ExerciseProgress>? exercises,
    double? completionPercentage,
    int? caloriesBurned,
    int? durationMinutes,
  }) {
    return WorkoutProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutId: workoutId ?? this.workoutId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}

/// Tracks progress for a single exercise within a workout
class ExerciseProgress {
  final String id;           // Unique identifier
  final String exerciseId;   // Reference to the exercise
  final int orderIndex;      // Position in workout
  final List<SetProgress> sets; // Progress on each set
  final bool isCompleted;    // Whether all sets are completed
  final DateTime? startedAt; // When user started this exercise
  final DateTime? completedAt; // When user completed this exercise
  
  ExerciseProgress({
    required this.id,
    required this.exerciseId,
    required this.orderIndex,
    required this.sets,
    required this.isCompleted,
    this.startedAt,
    this.completedAt,
  });

  /// Create from Firestore document
  factory ExerciseProgress.fromFirestore(DocumentSnapshot doc, {List<SetProgress>? sets}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse timestamps
    Timestamp? startTimestamp = data['startedAt'] as Timestamp?;
    Timestamp? completeTimestamp = data['completedAt'] as Timestamp?;
    
    return ExerciseProgress(
      id: doc.id,
      exerciseId: data['exerciseId'] ?? '',
      orderIndex: data['orderIndex'] ?? 0,
      sets: sets ?? [],
      isCompleted: data['isCompleted'] ?? false,
      startedAt: startTimestamp?.toDate(),
      completedAt: completeTimestamp?.toDate(),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'exerciseId': exerciseId,
      'orderIndex': orderIndex,
      'isCompleted': isCompleted,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'setCount': sets.length,
      'completedSetCount': sets.where((set) => set.isCompleted).length,
    };
  }

  /// Create a copy with modified fields
  ExerciseProgress copyWith({
    String? id,
    String? exerciseId,
    int? orderIndex,
    List<SetProgress>? sets,
    bool? isCompleted,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return ExerciseProgress(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      sets: sets ?? this.sets,
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Tracks progress for a single set within an exercise
class SetProgress {
  final int setNumber;      // Set number (1-based)
  final bool isCompleted;   // Whether this set is completed
  final int? actualReps;    // Actual reps completed (optional)
  final double? actualWeight; // Actual weight used (optional)
  final int? actualDurationSeconds; // Actual duration (for timed exercises)
  final String? notes;      // User notes for this set
  
  SetProgress({
    required this.setNumber,
    required this.isCompleted,
    this.actualReps,
    this.actualWeight,
    this.actualDurationSeconds,
    this.notes,
  });

  /// Create from Map data
  factory SetProgress.fromMap(Map<String, dynamic> data) {
    return SetProgress(
      setNumber: data['setNumber'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      actualReps: data['actualReps'],
      actualWeight: data['actualWeight']?.toDouble(),
      actualDurationSeconds: data['actualDurationSeconds'],
      notes: data['notes'],
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'isCompleted': isCompleted,
      'actualReps': actualReps,
      'actualWeight': actualWeight,
      'actualDurationSeconds': actualDurationSeconds,
      'notes': notes,
    };
  }

  /// Create a copy with modified fields
  SetProgress copyWith({
    int? setNumber,
    bool? isCompleted,
    int? actualReps,
    double? actualWeight,
    int? actualDurationSeconds,
    String? notes,
  }) {
    return SetProgress(
      setNumber: setNumber ?? this.setNumber,
      isCompleted: isCompleted ?? this.isCompleted,
      actualReps: actualReps ?? this.actualReps,
      actualWeight: actualWeight ?? this.actualWeight,
      actualDurationSeconds: actualDurationSeconds ?? this.actualDurationSeconds,
      notes: notes ?? this.notes,
    );
  }
}

/// Status of a workout
enum WorkoutStatus {
  notStarted,   // Workout hasn't been started yet
  inProgress,   // Workout is in progress
  completed,    // Workout was completed fully
  partiallyCompleted, // Workout was started but not fully completed
  cancelled,    // Workout was cancelled midway
} 