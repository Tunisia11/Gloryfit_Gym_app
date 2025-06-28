// lib/services/event_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gloryfit_version_3/models/event/eventTicketModel.dart';
import 'package:gloryfit_version_3/models/event/eventmodel.dart';

import 'package:gloryfit_version_3/models/user_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _eventsCollection => _firestore.collection('events');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // --- Admin Methods ---
  Future<void> createEvent(Event event) async {
    await _eventsCollection.doc(event.id).set(event.toMap());
  }

  Future<List<Event>> getAllEvents() async {
    final snapshot = await _eventsCollection.orderBy('eventDate', descending: false).get();
    return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
  }

  // --- User Methods ---
  Future<void> joinEvent(Event event, UserModel user, {String? ticketCode}) async {
    // Basic validation
    if (event.attendeeIds.contains(user.id)) {
      throw Exception("You have already joined this event.");
    }

    // Handle different enrollment types
    switch (event.enrollmentType) {
      case EventEnrollmentType.open:
        // No special checks needed
        break;
      case EventEnrollmentType.ticketCode:
        if (ticketCode == null || !event.validTicketCodes.contains(ticketCode)) {
          throw Exception("Invalid ticket code.");
        }
        // A real implementation would also mark the code as used.
        break;
      case EventEnrollmentType.paid:
        // Placeholder for payment logic
        // await _paymentService.processPayment(event.price);
        break;
      case EventEnrollmentType.membersOnly:
        // Placeholder for membership check
        // if (!user.isPremium) throw Exception("This event is for members only.");
        break;
    }
    
    // If all checks pass, generate a ticket and update the event
    final ticketRef = _usersCollection.doc(user.id).collection('eventTickets').doc();
    final newTicket = EventTicket(
      ticketId: ticketRef.id,
      eventId: event.id,
      eventName: event.name,
      userId: user.id,
      userName: user.displayName ?? 'No Name',
      userPhotoUrl: user.photoURL ?? '',
      issuedAt: DateTime.now(),
    );

    final eventRef = _eventsCollection.doc(event.id);

    WriteBatch batch = _firestore.batch();
    batch.set(ticketRef, newTicket.toMap());
    batch.update(eventRef, {'attendeeIds': FieldValue.arrayUnion([user.id])});
    
    await batch.commit();
  }
  
  Future<List<EventTicket>> getMyTickets(String userId) async {
      final snapshot = await _usersCollection
          .doc(userId)
          .collection('eventTickets')
          .orderBy('issuedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => EventTicket.fromFirestore(doc)).toList();
  }


  // --- Ticket Verification (For Admin Scanner) ---
  Future<EventTicket> getTicketDetails(String userId, String ticketId) async {
    final doc = await _usersCollection.doc(userId).collection('eventTickets').doc(ticketId).get();
    if (!doc.exists) {
      throw Exception("Ticket not found.");
    }
    return EventTicket.fromFirestore(doc);
  }
  
  Future<String> markTicketAsUsed(String userId, String ticketId) async {
    final ticketRef = _usersCollection.doc(userId).collection('eventTickets').doc(ticketId);
    final doc = await ticketRef.get();
    
    if(!doc.exists) throw Exception("Ticket does not exist.");
    final ticket = EventTicket.fromFirestore(doc);
    if(ticket.isUsed) throw Exception("This ticket has already been used at ${ticket.usedAt?.toLocal()}.");

    await ticketRef.update({
      'isUsed': true,
      'usedAt': Timestamp.now(),
    });
    
    return "Success! Welcome, ${ticket.userName}.";
  }
}
