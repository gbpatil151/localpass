import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localpass/models/event.dart';
import 'package:localpass/models/pass.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. READ EVENTS (Event Feed)
  Stream<List<Event>> getEvents() {
    return _db
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Event.fromFirestore(doc))
        .toList());
  }

  // 2. READ PASSES (My Passes)
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

  // 3. ACQUIRE PASS (With Wallet Deduction)
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

  // 4. CHECK-IN LOGIC (Location Verification)
  Future<void> checkIn(Pass pass) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

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

    DocumentSnapshot eventDoc = await _db.collection('events').doc(pass.eventId).get();
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
      throw Exception('You are too far from the venue! (${distanceInMeters.toStringAsFixed(0)} meters away)');
    }
  }

  // 5. HELPER: PRE-CHECK ELIGIBILITY
  Future<Map<String, dynamic>> checkPurchaseEligibility(Event event) async {
    User? user = _auth.currentUser;
    if (user == null) return {'status': 'error', 'message': 'Not logged in'};

    DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return {'status': 'error', 'message': 'User record not found'};

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
}