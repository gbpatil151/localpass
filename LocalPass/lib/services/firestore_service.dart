import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localpass/models/event.dart';
import 'package:localpass/models/pass.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Event>> getEvents() {
    return _db
        .collection('events')
        .where('date', isGreaterThan: Timestamp.now())
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  Stream<List<Pass>> getUpcomingPasses() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('myPasses')
        .where('status', isEqualTo: 'upcoming')
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) {
      DateTime now = DateTime.now();

      for (var doc in snapshot.docs) {
        Timestamp eventTs = doc['eventDate'];
        if (now.isAfter(eventTs.toDate().add(const Duration(hours: 5)))) {
          doc.reference.update({'status': 'expired'});
        }
      }

      return snapshot.docs.map((doc) => Pass.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Pass>> getPassHistory() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('myPasses')
        .where('status', whereIn: ['used', 'expired'])
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Pass.fromFirestore(doc)).toList());
  }

  Future<void> getPass(Event event) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('You must be logged in.');

    DocumentReference userDocRef = _db.collection('users').doc(user.uid);
    CollectionReference userPasses = userDocRef.collection('myPasses');

    await _db.runTransaction((transaction) async {
      DocumentSnapshot userSnapshot = await transaction.get(userDocRef);
      if (!userSnapshot.exists) {
        throw Exception("User record not found.");
      }

      int currentBalance = userSnapshot.get('walletBalance') ?? 0;

      QuerySnapshot existingPasses = await userPasses
          .where('eventId', isEqualTo: event.id)
          .limit(1)
          .get();

      if (existingPasses.docs.isNotEmpty) {
        throw Exception('You already have this pass.');
      }

      if (currentBalance < event.cost) {
        throw Exception('Insufficient funds! You need \$${event.cost}.');
      }

      int newBalance = currentBalance - (event.cost as int);
      transaction.update(userDocRef, {'walletBalance': newBalance});

      DocumentReference newPassRef = userPasses.doc();
      transaction.set(newPassRef, {
        'eventId': event.id,
        'eventName': event.title,
        'eventDate': event.date,
        'status': 'upcoming',
        'acquiredDate': Timestamp.now(),
      });
    });
  }

  Future<void> checkIn(Pass pass) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    DateTime now = DateTime.now();
    DateTime eventTime = pass.eventDate.toDate();

    DateTime checkInStart = eventTime.subtract(const Duration(hours: 2));
    DateTime checkInEnd = eventTime.add(const Duration(hours: 5));

    if (now.isBefore(checkInStart)) {
      throw Exception('Too early! Check-in starts 2 hours before the event.');
    }
    if (now.isAfter(checkInEnd)) {
      throw Exception('Too late! Check-in for this event has closed.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    Position userPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    DocumentSnapshot eventDoc =
    await _db.collection('events').doc(pass.eventId).get();
    if (!eventDoc.exists) throw Exception('Event data not found');

    Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
    GeoPoint eventLocation = eventData['location'];

    double distanceInMeters = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      eventLocation.latitude,
      eventLocation.longitude,
    );

    if (distanceInMeters <= 150) {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('myPasses')
          .doc(pass.id)
          .update({'status': 'used'});
    } else {
      throw Exception(
          'You are too far from the venue! (${distanceInMeters.toStringAsFixed(0)} meters away)');
    }
  }

  Future<Map<String, dynamic>> checkPurchaseEligibility(Event event) async {
    User? user = _auth.currentUser;
    if (user == null) return {'status': 'error', 'message': 'Not logged in'};

    DateTime now = DateTime.now();
    DateTime eventTime = event.date.toDate();
    DateTime salesDeadline = eventTime.subtract(const Duration(hours: 1));

    if (now.isAfter(salesDeadline)) {
      return {'status': 'sales_closed'};
    }

    DocumentSnapshot userDoc =
    await _db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      return {'status': 'error', 'message': 'User record not found'};
    }

    int currentBalance = userDoc.get('walletBalance') ?? 0;

    QuerySnapshot existing = await _db
        .collection('users')
        .doc(user.uid)
        .collection('myPasses')
        .where('eventId', isEqualTo: event.id)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return {'status': 'duplicate'};
    }

    if (currentBalance < event.cost) {
      return {
        'status': 'low_balance',
        'currentBalance': currentBalance,
        'needed': event.cost
      };
    }

    return {'status': 'ok', 'currentBalance': currentBalance};
  }

  Future<void> addEvent({
    required String title,
    required String description,
    required DateTime date,
    required String category,
    required int cost,
    required String organizer,
    required double latitude,
    required double longitude,
  }) async {
    await _db.collection('events').add({
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'category': category,
      'cost': cost,
      'organizer': organizer,
      'location': GeoPoint(latitude, longitude),
    });
  }
}