import 'package:cloud_firestore/cloud_firestore.dart';

enum EventEnrollmentType { open, ticketCode, paid, membersOnly }

class Event {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String location;
  final DateTime eventDate;
  final String createdBy; // Admin/Trainer ID
  final EventEnrollmentType enrollmentType;
  final List<String> validTicketCodes; // Only used if enrollmentType is ticketCode
  final double price; // Only used if enrollmentType is paid
  final List<String> attendeeIds;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.eventDate,
    required this.createdBy,
    required this.enrollmentType,
    this.validTicketCodes = const [],
    this.price = 0.0,
    this.attendeeIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'location': location,
      'eventDate': Timestamp.fromDate(eventDate),
      'createdBy': createdBy,
      'enrollmentType': enrollmentType.name,
      'validTicketCodes': validTicketCodes,
      'price': price,
      'attendeeIds': attendeeIds,
    };
  }

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] ?? '',
      eventDate: (data['eventDate'] as Timestamp? ?? Timestamp.now()).toDate(),
      createdBy: data['createdBy'] ?? '',
      enrollmentType: EventEnrollmentType.values.byName(data['enrollmentType'] ?? 'open'),
      validTicketCodes: List<String>.from(data['validTicketCodes'] ?? []),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      attendeeIds: List<String>.from(data['attendeeIds'] ?? []),
    );
  }
}
