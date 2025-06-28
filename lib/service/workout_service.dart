// lib/service/workout_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gloryfit_version_3/models/workout_model.dart';
import 'package:gloryfit_version_3/models/workout_progress_model.dart';
import 'package:gloryfit_version_3/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

/// Service for managing workouts in Firestore.
/// Handles CRUD operations for workouts and user workout progress.
class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  // Collection references for better readability and maintenance.
  CollectionReference get _workoutsCollection =>
      _firestore.collection('workouts');
  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<List<Workout>> getAllWorkouts() async {
    try {
      final querySnapshot = await _workoutsCollection.get();
      // Fetch all exercises concurrently for better performance.
      final workouts = await Future.wait(querySnapshot.docs.map((doc) async {
        final exercises = await _getWorkoutExercises(doc.id);
        return Workout.fromFirestore(doc, exercises: exercises);
      }));
      return workouts;
    } catch (e) {
      print('Error getting workouts: $e');
      rethrow;
    }
  }

  /// Fetches a single workout by its ID, including its exercises.
  Future<Workout?> getWorkoutById(String workoutId) async {
    try {
      final doc = await _workoutsCollection.doc(workoutId).get();
      if (!doc.exists) return null;
      final exercises = await _getWorkoutExercises(workoutId);
      return Workout.fromFirestore(doc, exercises: exercises);
    } catch (e) {
      print('Error getting workout by ID: $e');
      rethrow;
    }
  }

  /// Creates a new workout and its associated exercises in a single batch operation.
  Future<void> createWorkout(Workout workout, XFile imageFile) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final workoutRef = _workoutsCollection.doc();
    final WriteBatch batch = _firestore.batch();

    // 1. Upload the workout cover image.
    final imageUrl = await _storageService.uploadImage(
        imageFile: imageFile, bucket: 'workout-covers');

    // 2. Set the main workout data with the generated ID and image URL.
    batch.set(
        workoutRef,
        workout
            .copyWith(
                id: workoutRef.id,
                createdBy: currentUser.uid,
                imageUrl: imageUrl)
            .toFirestore());

    // 3. Add each WorkoutExercise to the 'exercises' subcollection.
    for (final exercise in workout.exercises) {
      final exerciseRef = workoutRef.collection('exercises').doc();
      batch.set(
          exerciseRef, exercise.copyWith(id: exerciseRef.id).toFirestore());
    }

    await batch.commit();
  }

  Future<void> deleteWorkout(String workoutId) async {
    // Note: A complete solution would also delete all sub-collection documents.
    await _workoutsCollection.doc(workoutId).delete();
  }

  // Helper method to fetch the exercises for a specific workout.
  Future<List<WorkoutExercise>> _getWorkoutExercises(String workoutId) async {
    final exercisesSnapshot = await _workoutsCollection
        .doc(workoutId)
        .collection('exercises')
        .orderBy('orderIndex')
        .get();
    return exercisesSnapshot.docs
        .map((doc) => WorkoutExercise.fromFirestore(doc))
        .toList();
  }

  /// Starts a new workout session for the current user.
  Future<WorkoutProgress?> startWorkout(String workoutId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final Workout? workout = await getWorkoutById(workoutId);
      if (workout == null) throw Exception('Workout not found');

      final progressRef =
          _usersCollection.doc(currentUser.uid).collection('workoutProgress').doc();
      final WriteBatch batch = _firestore.batch();
      
      // **FIX**: Create the list of ExerciseProgress objects in memory first.
      final List<ExerciseProgress> exerciseProgressList = [];

      // Create a document for each exercise in the progress subcollection.
      for (final exercise in workout.exercises) {
        final exerciseProgressRef = progressRef.collection('exercises').doc(); // Keep generating new IDs for Firestore
        final setProgresses = List.generate(
          exercise.sets,
          (i) => SetProgress(setNumber: i + 1, isCompleted: false),
        );
        final exerciseProgress = ExerciseProgress(
          id: exerciseProgressRef.id,
          exerciseId: exercise.exerciseId,
          orderIndex: exercise.orderIndex,
          sets: setProgresses,
          isCompleted: false,
        );

        exerciseProgressList.add(exerciseProgress); // Add to the local list
        batch.set(exerciseProgressRef,
            exerciseProgress.toFirestore()); // Add the DB operation to the batch
      }

      // **FIX**: The main progress object now includes the populated exercise list.
      final progress = WorkoutProgress(
        id: progressRef.id,
        userId: currentUser.uid,
        workoutId: workoutId,
        startedAt: DateTime.now(),
        status: WorkoutStatus.inProgress,
        exercises: exerciseProgressList, // Use the populated list here.
        completionPercentage: 0,
        caloriesBurned: 0,
        durationMinutes: 0,
      );
      batch.set(progressRef, progress.toFirestore());

      await batch.commit();
      return progress; // Return the fully-formed object.
    } catch (e) {
      print('Error starting workout: $e');
      return null;
    }
  }

  /// Updates the state of an in-progress workout.
  Future<bool> updateWorkoutProgress(WorkoutProgress progress) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');
      if (progress.userId != currentUser.uid)
        throw Exception('Unauthorized access');

      final WriteBatch batch = _firestore.batch();
      final progressRef = _usersCollection
          .doc(currentUser.uid)
          .collection('workoutProgress')
          .doc(progress.id);

      batch.update(progressRef, progress.toFirestore());

      for (final exerciseProgress in progress.exercises) {
        final exerciseProgressRef =
            progressRef.collection('exercises').doc(exerciseProgress.id);
        batch.update(exerciseProgressRef, exerciseProgress.toFirestore());
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error updating workout progress: $e');
      return false;
    }
  }

  /// Gets the user's currently in-progress workout, if one exists.
  Future<WorkoutProgress?> getInProgressWorkout() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final progressSnapshot = await _usersCollection
          .doc(currentUser.uid)
          .collection('workoutProgress')
          .where('status', isEqualTo: WorkoutStatus.inProgress.name)
          .limit(1)
          .get();

      if (progressSnapshot.docs.isEmpty) return null;

      final doc = progressSnapshot.docs.first;
      final exerciseProgressSnapshot =
          await doc.reference.collection('exercises').orderBy('orderIndex').get();

      final exerciseProgresses = exerciseProgressSnapshot.docs
          .map((exerciseDoc) => ExerciseProgress.fromFirestore(
              exerciseDoc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      return WorkoutProgress.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>,
        exercises: exerciseProgresses,
      );
    } catch (e) {
      print('Error getting in-progress workout: $e');
      return null;
    }
  }
}
