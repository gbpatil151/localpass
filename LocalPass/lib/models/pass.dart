import 'package:cloud_firestore/cloud_firestore.dart';

class Pass {
  final String id;
  final String eventId;
  final String eventName;
  final Timestamp eventDate;
  final String status; // 'upcoming' / 'used'
  final Timestamp acquiredDate;

  Pass({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.status,
    required this.acquiredDate,
  });

  factory Pass.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Pass(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      eventName: data['eventName'] ?? 'Unknown Event',
      eventDate: data['eventDate'] ?? Timestamp.now(),
      status: data['status'] ?? 'upcoming',
      acquiredDate: data['acquiredDate'] ?? Timestamp.now(),
    );
  }
}