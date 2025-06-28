import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gloryfit_version_3/models/classes/classMembership.dart';
import 'package:gloryfit_version_3/models/classes/class_model.dart';
import 'package:gloryfit_version_3/models/classes/join_request.dart';

import 'package:gloryfit_version_3/models/user_model.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _classesCollection = 'classes';
  final String _membershipsCollection = 'classMemberships';
  final String _requestsCollection = 'joinRequests';

  /// Admin: Creates a new class
  Future<void> createClass(Class newClass) async {
    try {
      await _firestore
          .collection(_classesCollection)
          .doc(newClass.id)
          .set(newClass.toMap());
    } catch (e) {
      print('Error creating class: $e');
      rethrow;
    }
  }

  /// User: Fetches all available classes for the discovery screen
  Future<List<Class>> getClasses() async {
    try {
      final snapshot = await _firestore
          .collection(_classesCollection)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Class.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching classes: $e');
      rethrow;
    }
  }

  /// User: Requests to join a class that requires approval
  Future<void> requestToJoinClass(Class aClass, UserModel user) async {
    try {
      final requestRef = _firestore.collection(_requestsCollection).doc();
      final newRequest = JoinRequest(
        id: requestRef.id,
        userId: user.id,
        classId: aClass.id,
        className: aClass.name,
        userName: user.displayName ?? 'Unknown',
        userPhotoUrl: user.photoURL ?? '',
        requestedAt: DateTime.now(),
        status: JoinRequestStatus.pending,
      );
      await requestRef.set(newRequest.toMap());
    } catch (e) {
      print('Error requesting to join class: $e');
      rethrow;
    }
  }

  /// Admin: Approves a join request for a class
  Future<void> approveJoinRequest(String requestId) async {
    try {
      final requestRef = _firestore.collection(_requestsCollection).doc(requestId);
      final requestDoc = await requestRef.get();
      if (!requestDoc.exists) throw Exception("Request not found");

      final request = JoinRequest.fromFirestore(requestDoc);
      final classRef = _firestore.collection(_classesCollection).doc(request.classId);
      final membershipRef = _firestore.collection(_membershipsCollection).doc();

      final newMembership = ClassMembership(
          id: membershipRef.id,
          userId: request.userId,
          classId: request.classId,
          userName: request.userName,
          userPhotoUrl: request.userPhotoUrl,
          joinedAt: DateTime.now(),
          status: MembershipStatus.active);

      // Using a batch write to ensure atomicity
      WriteBatch batch = _firestore.batch();
      // 1. Add user to the class's member list
      batch.update(classRef, {
        'memberIds': FieldValue.arrayUnion([request.userId])
      });
      // 2. Create the membership document
      batch.set(membershipRef, newMembership.toMap());
      // 3. Update the request status to 'approved'
      batch.update(requestRef, {'status': JoinRequestStatus.approved.name});
      
      await batch.commit();

    } catch (e) {
      print('Error approving join request: $e');
      rethrow;
    }
  }

  /// User: Joins a free class directly
  Future<void> joinFreeClass(Class aClass, UserModel user) async {
     try {
        final classRef = _firestore.collection(_classesCollection).doc(aClass.id);
        final membershipRef = _firestore.collection(_membershipsCollection).doc();

         final newMembership = ClassMembership(
          id: membershipRef.id,
          userId: user.id,
          classId: aClass.id,
          userName: user.displayName ?? 'Unknown',
          userPhotoUrl: user.photoURL ?? '',
          joinedAt: DateTime.now(),
          status: MembershipStatus.active);

        WriteBatch batch = _firestore.batch();
        batch.update(classRef, {'memberIds': FieldValue.arrayUnion([user.id])});
        batch.set(membershipRef, newMembership.toMap());
        await batch.commit();

     } catch (e) {
        print('Error joining free class: $e');
        rethrow;
     }
  }
}
