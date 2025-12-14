import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localpass/models/event.dart';
import 'package:localpass/models/pass.dart';

// Service handling all Firestore operations for events and passes
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of upcoming events ordered by date
  Stream<List<Event>> getEvents() {
    return _db
        .collection('events')
        .where('date', isGreaterThan: Timestamp.now())
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  // Stream of user's upcoming passes, auto-expires passes 5 hours after event
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

      // Auto-expire passes 5 hours after event time
      for (var doc in snapshot.docs) {
        Timestamp eventTs = doc['eventDate'];
        if (now.isAfter(eventTs.toDate().add(const Duration(hours: 5)))) {
          doc.reference.update({'status': 'expired'});
        }
      }

      return snapshot.docs.map((doc) => Pass.fromFirestore(doc)).toList();
    });
  }

  // Stream of user's pass history (used or expired passes)
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

  // Purchases a pass for an event using transaction to ensure data consistency
  Future<void> getPass(Event event) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('You must be logged in.');

    DocumentReference userDocRef = _db.collection('users').doc(user.uid);
    CollectionReference userPasses = userDocRef.collection('myPasses');

    // Use transaction to atomically check balance and create pass
    await _db.runTransaction((transaction) async {
      DocumentSnapshot userSnapshot = await transaction.get(userDocRef);
      if (!userSnapshot.exists) {
        throw Exception("User record not found.");
      }

      int currentBalance = userSnapshot.get('walletBalance') ?? 0;

      // Check if user already has this pass
      QuerySnapshot existingPasses = await userPasses
          .where('eventId', isEqualTo: event.id)
          .limit(1)
          .get();

      if (existingPasses.docs.isNotEmpty) {
        throw Exception('You already have this pass.');
      }

      // Check if user has sufficient balance
      if (currentBalance < event.cost) {
        throw Exception('Insufficient funds! You need \$${event.cost}.');
      }

      // Deduct cost from wallet and create pass
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

  // Checks in user for an event - validates time window and location proximity
  Future<void> checkIn(Pass pass) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    DateTime now = DateTime.now();
    DateTime eventTime = pass.eventDate.toDate();

    // Check-in window: 2 hours before to 5 hours after event
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

    // Get user's current location
    Position userPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Get event location from Firestore
    DocumentSnapshot eventDoc =
    await _db.collection('events').doc(pass.eventId).get();
    if (!eventDoc.exists) throw Exception('Event data not found');

    Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
    GeoPoint eventLocation = eventData['location'];

    // Calculate distance between user and event location
    double distanceInMeters = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      eventLocation.latitude,
      eventLocation.longitude,
    );

    // Check-in successful if within 150 meters of venue
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

  // Checks if user is eligible to purchase a pass (balance, duplicates, sales deadline)
  Future<Map<String, dynamic>> checkPurchaseEligibility(Event event) async {
    User? user = _auth.currentUser;
    if (user == null) return {'status': 'error', 'message': 'Not logged in'};

    DateTime now = DateTime.now();
    DateTime eventTime = event.date.toDate();
    // Sales close 1 hour before event
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

  // Creates a new event in Firestore
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