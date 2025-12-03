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
        .where('date', isGreaterThan: Timestamp.now())
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Event.fromFirestore(doc))
        .toList());
  }

  // 2. READ PASSES (My Passes)
  // ==============================================================================
  // 2. READ PASSES (My Passes & History)
  // ==============================================================================

  // A. Get Upcoming Passes (and auto-expire old ones)
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
      // --- LAZY EXPIRATION LOGIC ---
      // While we are reading the list, check for old events
      DateTime now = DateTime.now();

      for (var doc in snapshot.docs) {
        Timestamp eventTs = doc['eventDate'];
        // If event ended more than 5 hours ago (check-in window closed)
        if (now.isAfter(eventTs.toDate().add(Duration(hours: 5)))) {
          // Update status to 'expired' in the background
          doc.reference.update({'status': 'expired'});
        }
      }
      // -----------------------------

      return snapshot.docs
          .map((doc) => Pass.fromFirestore(doc))
          .toList();
    });
  }

  // B. Get History (Used AND Expired)
  Stream<List<Pass>> getPassHistory() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('myPasses')
        .where('status', whereIn: ['used', 'expired']) // Fetch both types
        .orderBy('eventDate', descending: true) // Newest first for history
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

// ==============================================================================
  // 4. CHECK-IN LOGIC (Location + Time Verification)
  // ==============================================================================
  Future<void> checkIn(Pass pass) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // --- NEW: CHECK TIME WINDOW ---
    DateTime now = DateTime.now();
    DateTime eventTime = pass.eventDate.toDate();

    // Define window: 2 hours before -> 5 hours after
    DateTime checkInStart = eventTime.subtract(const Duration(hours: 2));
    DateTime checkInEnd = eventTime.add(const Duration(hours: 5));

    if (now.isBefore(checkInStart)) {
      throw Exception('Too early! Check-in starts 2 hours before the event.');
    }
    if (now.isAfter(checkInEnd)) {
      throw Exception('Too late! Check-in for this event has closed.');
    }
    // -----------------------------

    // Check permissions
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

    // Get position
    Position userPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Get event location
    DocumentSnapshot eventDoc = await _db.collection('events').doc(pass.eventId).get();
    if (!eventDoc.exists) throw Exception('Event data not found');

    Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
    GeoPoint eventLocation = eventData['location'];

    // Calculate distance
    double distanceInMeters = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      eventLocation.latitude,
      eventLocation.longitude,
    );

    // Validate (150m radius)
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



  // ==============================================================================
  // 5. HELPER: PRE-CHECK ELIGIBILITY
  // ==============================================================================
  Future<Map<String, dynamic>> checkPurchaseEligibility(Event event) async {
    User? user = _auth.currentUser;
    if (user == null) return {'status': 'error', 'message': 'Not logged in'};

    // --- NEW: CHECK TIME RESTRICTION ---
    DateTime now = DateTime.now();
    DateTime eventTime = event.date.toDate();
    // Calculate the deadline (1 hour before event)
    DateTime salesDeadline = eventTime.subtract(const Duration(hours: 1));

    // If now is AFTER the deadline, sales are closed
    if (now.isAfter(salesDeadline)) {
      return {'status': 'sales_closed'};
    }
    // -----------------------------------

    // 1. Get User Balance
    DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return {'status': 'error', 'message': 'User record not found'};

    int currentBalance = userDoc.get('walletBalance') ?? 0;

    // 2. Check for Duplicates
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

    // 3. Check Funds
    if (currentBalance < event.cost) {
      return {
        'status': 'low_balance',
        'currentBalance': currentBalance,
        'needed': event.cost
      };
    }

    // 4. All Good!
    return {'status': 'ok', 'currentBalance': currentBalance};
  }
}