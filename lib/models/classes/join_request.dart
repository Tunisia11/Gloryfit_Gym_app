import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequest {
  final String id;
  final String userId;
  final String classId;
  final String className; // Denormalized
  final String userName; // Denormalized
  final String userPhotoUrl; // Denormalized
  final DateTime requestedAt;
  final JoinRequestStatus status;

  JoinRequest({
    required this.id,
    required this.userId,
    required this.classId,
    required this.className,
    required this.userName,
    required this.userPhotoUrl,
    required this.requestedAt,
    this.status = JoinRequestStatus.pending,
  });

  factory JoinRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return JoinRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      status: JoinRequestStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => JoinRequestStatus.pending),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'classId': classId,
      'className': className,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status.name,
    };
  }
}

enum JoinRequestStatus {
  pending,
  approved,
  denied,
}
