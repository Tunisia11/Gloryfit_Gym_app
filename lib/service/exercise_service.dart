import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gloryfit_version_3/models/exercise_model.dart';
import 'package:gloryfit_version_3/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  CollectionReference get _exercisesCollection =>
      _firestore.collection('exercises');

  /// Fetches all exercises from Firestore.
  Future<List<Exercise>> getAllExercises() async {
    try {
      final snapshot =
          await _exercisesCollection.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting exercises: $e');
      throw Exception('Failed to load exercises.');
    }
  }

  /// Creates a new exercise document in Firestore after uploading its media.
  Future<void> createExercise({
    required String name,
    required String description,
    required List<String> targetMuscles,
    required XFile videoFile,
    XFile? imageFile, // Optional image
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    try {
      // 1. Upload video to Supabase and get URL
      final videoUrl = await _storageService.uploadImage(
        imageFile: videoFile, // XFile can handle video types
        bucket: 'exercise-videos',
      );

      // 2. Upload image (if provided)
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageService.uploadImage(
          imageFile: imageFile,
          bucket: 'exercise-images',
        );
      }

      // 3. Create the Exercise object with a new ID
      final newExerciseRef = _exercisesCollection.doc();
      final newExercise = Exercise(
        id: newExerciseRef.id,
        name: name,
        description: description,
        videoUrl: videoUrl,
        imageUrl: imageUrl,
        targetMuscles: targetMuscles,
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      // 4. Save to Firestore
      await newExerciseRef.set(newExercise.toFirestore());
    } catch (e) {
      print('Error creating exercise: $e');
      throw Exception('Failed to create exercise.');
    }
  }
  
  /// Deletes an exercise from Firestore.
  Future<void> deleteExercise(String exerciseId) async {
    try {
      // Note: A complete solution would also delete the image/video from Supabase Storage.
      await _exercisesCollection.doc(exerciseId).delete();
    } catch (e) {
      print('Error deleting exercise: $e');
      throw Exception('Failed to delete exercise.');
    }
  }
}
