import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String category;
  final num cost;
  final Timestamp date;
  final String description;
  final GeoPoint location;
  final String organizer;

  Event({
    required this.id,
    required this.title,
    required this.category,
    required this.cost,
    required this.date,
    required this.description,
    required this.location,
    required this.organizer,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      cost: data['cost'] ?? 0,
      date: data['date'] ?? Timestamp.now(),
      description: data['description'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      organizer: data['organizer'] ?? '',
    );
  }
}