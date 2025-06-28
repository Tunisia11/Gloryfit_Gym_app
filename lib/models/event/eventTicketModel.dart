
// lib/models/event_ticket_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EventTicket {
  final String ticketId; // Unique ID for this ticket
  final String eventId;
  final String eventName;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final DateTime issuedAt;
  final bool isUsed; // To prevent multiple entries
  final DateTime? usedAt;

  EventTicket({
    required this.ticketId,
    required this.eventId,
    required this.eventName,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.issuedAt,
    this.isUsed = false,
    this.usedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'isUsed': isUsed,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }

  factory EventTicket.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventTicket(
      ticketId: doc.id,
      eventId: data['eventId'] ?? '',
      eventName: data['eventName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      issuedAt: (data['issuedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      isUsed: data['isUsed'] ?? false,
      usedAt: (data['usedAt'] as Timestamp?)?.toDate(),
    );
  }
}
