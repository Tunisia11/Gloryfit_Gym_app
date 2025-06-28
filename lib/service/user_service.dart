import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gloryfit_version_3/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Create or update user document
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).set(
        user.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Update user onboarding status
  Future<void> updateOnboardingStatus(String userId, bool isCompleted) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'isOnboardingCompleted': isCompleted,
      });
    } catch (e) {
      throw Exception('Failed to update onboarding status: $e');
    }
  }

  // Update user profile data
  Future<void> updateUserProfile({
    required String userId,
    DateTime? dateOfBirth,
    Gender? gender,
    double? height,
    double? weight,
    FitnessGoal? fitnessGoal,
    int? trainingDaysPerWeek,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (dateOfBirth != null) updates['dateOfBirth'] = dateOfBirth.toIso8601String();
      if (gender != null) updates['gender'] = gender.toString().split('.').last;
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;
      if (fitnessGoal != null) updates['fitnessGoal'] = fitnessGoal.toString().split('.').last;
      if (trainingDaysPerWeek != null) updates['trainingDaysPerWeek'] = trainingDaysPerWeek;

      await _firestore.collection(_collection).doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
} 