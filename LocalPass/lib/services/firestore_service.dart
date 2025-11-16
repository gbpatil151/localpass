import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localpass/models/event.dart'; // Import your new model

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get a stream of all events, ordered by date
  Stream<List<Event>> getEvents() {
    return _db
        .collection('events')
        .orderBy('date', descending: false) // Sort by date (MVP requirement)
        .snapshots() // This is the live stream
        .map((snapshot) => snapshot.docs
        .map((doc) => Event.fromFirestore(doc)) // Convert each doc to an Event object
        .toList());
  }

// We will add more methods here in Stage 3 (like adding a pass)
}