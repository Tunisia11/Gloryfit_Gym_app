import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gloryfit_version_3/models/classes/classMembership.dart';
import 'package:gloryfit_version_3/models/classes/join_request.dart';

import 'package:gloryfit_version_3/models/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the main statistics for the admin dashboard.
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final results = await Future.wait([
        _firestore.collection('users').count().get(),
        _firestore.collection('workouts').count().get(),
        _firestore.collection('exercises').count().get(),
        _firestore.collection('classes').count().get(),
      ]);
      return {
        'totalUsers': results[0].count!,
        'totalWorkouts': results[1].count!,
        'totalExercises': results[2].count!,
        'totalClasses': results[3].count!,
      };
    } catch (e) {
      print("Error fetching dashboard stats: $e");
      rethrow;
    }
  }

  /// Fetches all users from the database.
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  /// Updates the role of a specific user.
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'role': newRole.name});
  }

  /// Fetches all pending join requests across all classes.
  Future<List<JoinRequest>> getPendingJoinRequests() async {
    final snapshot = await _firestore
        .collection('joinRequests')
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .orderBy('requestedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => JoinRequest.fromFirestore(doc)).toList();
  }

  /// Approves a user's request to join a class.
  Future<void> approveJoinRequest(JoinRequest request) async {
    final requestRef = _firestore.collection('joinRequests').doc(request.id);
    final classRef = _firestore.collection('classes').doc(request.classId);
    final membershipRef = _firestore.collection('classMemberships').doc();

    final newMembership = ClassMembership(
        id: membershipRef.id,
        userId: request.userId,
        classId: request.classId,
        userName: request.userName,
        userPhotoUrl: request.userPhotoUrl,
        joinedAt: DateTime.now(),
        status: MembershipStatus.active);

    WriteBatch batch = _firestore.batch();
    batch.update(classRef, {'memberIds': FieldValue.arrayUnion([request.userId])});
    batch.set(membershipRef, newMembership.toMap());
    batch.update(requestRef, {'status': JoinRequestStatus.approved.name});
    await batch.commit();
  }

  /// Denies a user's request to join a class.
  Future<void> denyJoinRequest(String requestId) async {
    await _firestore.collection('joinRequests').doc(requestId).update({
      'status': JoinRequestStatus.denied.name,
    });
  }
}
