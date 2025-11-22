import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localpass/models/event.dart';
import 'package:localpass/models/pass.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Event>> getEvents() {
    return _db
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Event.fromFirestore(doc))
        .toList());
  }

  Future<void> getPass(Event event) async {
    User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to get a pass.');
    }

    CollectionReference userPasses =
    _db.collection('users').doc(user.uid).collection('myPasses');

    QuerySnapshot existingPasses = await userPasses
        .where('eventId', isEqualTo: event.id)
        .limit(1)
        .get();

    if (existingPasses.docs.isNotEmpty) {
      throw Exception('Pass for "${event.title}" is already in your passes list.');
    }

    Map<String, dynamic> passData = {
      'eventId': event.id,
      'eventName': event.title,
      'eventDate': event.date,
      'status': 'upcoming',
      'acquiredDate': Timestamp.now(),
    };

    await userPasses.add(passData);
  }

  Stream<List<Pass>> getPasses(String status) {
    User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('myPasses')
        .where('status', isEqualTo: status)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Pass.fromFirestore(doc))
        .toList());
  }
}