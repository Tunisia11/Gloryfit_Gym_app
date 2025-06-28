import 'package:cloud_firestore/cloud_firestore.dart';

class ClassMembership {
  final String id;
  final String userId;
  final String classId;
  final String userName; // Denormalized for easy display
  final String userPhotoUrl; // Denormalized for easy display
  final DateTime joinedAt;
  final MembershipStatus status;

  ClassMembership({
    required this.id,
    required this.userId,
    required this.classId,
    required this.userName,
    required this.userPhotoUrl,
    required this.joinedAt,
    required this.status,
  });

   factory ClassMembership.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClassMembership(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      status: MembershipStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => MembershipStatus.inactive),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'classId': classId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'status': status.name,
    };
  }
}

enum MembershipStatus {
  active, // Currently in the class
  pending, // Requested to join, waiting for approval
  inactive, // Left or was removed
}
