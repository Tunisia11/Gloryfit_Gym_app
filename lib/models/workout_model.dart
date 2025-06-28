import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a workout session comprising multiple exercises
/// Created by admin/trainers and viewable by all users
class Workout {
  final String id;               // Unique identifier
  final String name;             // Workout name
  final String description;      // Workout description
  final String imageUrl;         // Cover image for the workout
  final String trainerName;      // Name of the trainer who created it
  final String trainerPhotoUrl;  // Trainer's photo
  final String createdBy;        // Admin/trainer user ID
  final DateTime createdAt;      // Creation timestamp
  final List<WorkoutExercise> exercises;  // List of exercises in this workout
  final List<String> targetMuscleGroups;  // Primary muscles targeted
  final WorkoutDifficulty difficulty;     // Difficulty level
  final int estimatedDurationMinutes;     // Estimated time to complete
  final int estimatedCaloriesBurn;        // Estimated calories burn
  final WorkoutType type;                 // Type of workout
  final int seriesCount;                  // Number of series/circuits
  
  /// Constructor requiring all necessary fields
  Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.trainerName,
    required this.trainerPhotoUrl,
    required this.createdBy,
    required this.createdAt,
    required this.exercises,
    required this.targetMuscleGroups,
    required this.difficulty,
    required this.estimatedDurationMinutes,
    required this.estimatedCaloriesBurn,
    required this.type,
    required this.seriesCount,
  });

  /// Create Workout from Firestore document
  factory Workout.fromFirestore(DocumentSnapshot doc, {List<WorkoutExercise>? exercises}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse timestamp or use current date as fallback
    Timestamp timestamp = data['createdAt'] as Timestamp? ?? Timestamp.now();
    
    return Workout(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      trainerName: data['trainerName'] ?? 'GloryFit Trainer',
      trainerPhotoUrl: data['trainerPhotoUrl'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: timestamp.toDate(),
      exercises: exercises ?? [], // This would typically be loaded separately
      targetMuscleGroups: List<String>.from(data['targetMuscleGroups'] ?? []),
      difficulty: _parseWorkoutDifficulty(data['difficulty']),
      estimatedDurationMinutes: data['estimatedDurationMinutes'] ?? 0,
      estimatedCaloriesBurn: data['estimatedCaloriesBurn'] ?? 0,
      type: _parseWorkoutType(data['type']),
      seriesCount: data['seriesCount'] ?? 1,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'trainerName': trainerName,
      'trainerPhotoUrl': trainerPhotoUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'targetMuscleGroups': targetMuscleGroups,
      'difficulty': difficulty.toString().split('.').last,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'estimatedCaloriesBurn': estimatedCaloriesBurn,
      'type': type.toString().split('.').last,
      'seriesCount': seriesCount,
      'exerciseCount': exercises.length,
    };
  }

  /// Helper to parse workout difficulty from string
  static WorkoutDifficulty _parseWorkoutDifficulty(String? value) {
    if (value == null) return WorkoutDifficulty.beginner;
    
    try {
      return WorkoutDifficulty.values.firstWhere(
        (difficulty) => difficulty.toString().split('.').last == value,
      );
    } catch (_) {
      return WorkoutDifficulty.beginner;
    }
  }

  /// Helper to parse workout type from string
  static WorkoutType _parseWorkoutType(String? value) {
    if (value == null) return WorkoutType.standard;
    
    try {
      return WorkoutType.values.firstWhere(
        (type) => type.toString().split('.').last == value,
      );
    } catch (_) {
      return WorkoutType.standard;
    }
  }

  /// Create a copy of Workout with modified fields
  Workout copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? trainerName,
    String? trainerPhotoUrl,
    String? createdBy,
    DateTime? createdAt,
    List<WorkoutExercise>? exercises,
    List<String>? targetMuscleGroups,
    WorkoutDifficulty? difficulty,
    int? estimatedDurationMinutes,
    int? estimatedCaloriesBurn,
    WorkoutType? type,
    int? seriesCount,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      trainerName: trainerName ?? this.trainerName,
      trainerPhotoUrl: trainerPhotoUrl ?? this.trainerPhotoUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      exercises: exercises ?? this.exercises,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      difficulty: difficulty ?? this.difficulty,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      estimatedCaloriesBurn: estimatedCaloriesBurn ?? this.estimatedCaloriesBurn,
      type: type ?? this.type,
      seriesCount: seriesCount ?? this.seriesCount,
    );
  }
}

/// Represents a single exercise entry within a workout
/// Contains all the detailed instructions for performing the exercise
class WorkoutExercise {
  final String id;               // Unique identifier
  final String exerciseId;       // Reference to the master exercise
  final String name;             // Exercise name (cached from Exercise)
  final String? imageUrl;        // Primary image (cached from Exercise)
  final String? videoUrl;        // Video URL (cached from Exercise)
  final int sets;                // Number of sets to perform
  final int repsPerSet;          // Repetitions per set (0 for time-based)
  final int? durationSeconds;    // Duration in seconds (for time-based)
  final int restBetweenSetsSeconds; // Rest time between sets
  final double? weightKg;        // Weight to use (null for bodyweight)
  final String? notes;           // Special instructions
  final int orderIndex;          // Order in the workout
  
  WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.name,
    this.imageUrl,
    this.videoUrl,
    required this.sets,
    required this.repsPerSet,
    this.durationSeconds,
    required this.restBetweenSetsSeconds,
    this.weightKg,
    this.notes,
    required this.orderIndex,
  });

  /// Create from Firestore document
  factory WorkoutExercise.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return WorkoutExercise(
      id: doc.id,
      exerciseId: data['exerciseId'] ?? '',
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      sets: data['sets'] ?? 3,
      repsPerSet: data['repsPerSet'] ?? 10,
      durationSeconds: data['durationSeconds'],
      restBetweenSetsSeconds: data['restBetweenSetsSeconds'] ?? 60,
      weightKg: data['weightKg']?.toDouble(),
      notes: data['notes'],
      orderIndex: data['orderIndex'] ?? 0,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'sets': sets,
      'repsPerSet': repsPerSet,
      'durationSeconds': durationSeconds,
      'restBetweenSetsSeconds': restBetweenSetsSeconds,
      'weightKg': weightKg,
      'notes': notes,
      'orderIndex': orderIndex,
    };
  }

  /// Create a copy with modified fields
  WorkoutExercise copyWith({
    String? id,
    String? exerciseId,
    String? name,
    String? imageUrl,
    String? videoUrl,
    int? sets,
    int? repsPerSet,
    int? durationSeconds,
    int? restBetweenSetsSeconds,
    double? weightKg,
    String? notes,
    int? orderIndex,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      sets: sets ?? this.sets,
      repsPerSet: repsPerSet ?? this.repsPerSet,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      restBetweenSetsSeconds: restBetweenSetsSeconds ?? this.restBetweenSetsSeconds,
      weightKg: weightKg ?? this.weightKg,
      notes: notes ?? this.notes,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

/// Difficulty levels for workouts
enum WorkoutDifficulty {
  beginner,     // Suitable for beginners
  intermediate, // For intermediate fitness levels
  advanced,     // For advanced trainees
  expert,       // For expert/professional athletes
}

/// Types of workout structures
enum WorkoutType {
  standard,      // Standard workout (sets x reps)
  circuit,       // Circuit training (minimal rest)
  hiit,          // High-intensity interval training
  amrap,         // As Many Rounds As Possible
  emom,          // Every Minute On the Minute
  tabata,        // Tabata protocol (20s work, 10s rest)
  supersets,     // Paired exercises with no rest between
  pyramid,       // Increasing/decreasing weights or reps
} 