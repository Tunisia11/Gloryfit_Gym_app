import 'package:cloud_firestore/cloud_firestore.dart';

class ClassSession {
  final String id;
  final String classId;
  final DateTime sessionDate;
  final String title;
  final String? description;
  final List<String> rsvpedUserIds; // List of user IDs who have RSVP'd

  ClassSession({
    required this.id,
    required this.classId,
    required this.sessionDate,
    required this.title,
    this.description,
    required this.rsvpedUserIds,
  });

  factory ClassSession.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClassSession(
      id: doc.id,
      classId: data['classId'] ?? '',
      sessionDate: (data['sessionDate'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      description: data['description'],
      rsvpedUserIds: List<String>.from(data['rsvpedUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'sessionDate': Timestamp.fromDate(sessionDate),
      'title': title,
      'description': description,
      'rsvpedUserIds': rsvpedUserIds,
    };
  }
}
