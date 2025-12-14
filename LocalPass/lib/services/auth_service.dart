import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Service handling user authentication and user profile creation
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Creates new user account and initializes user profile with wallet balance
  Future<User?> signUp(String email, String password, {String displayName = 'New User'}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      // Create user document with initial wallet balance
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'email': email,
          'displayName': displayName,
          'walletBalance': 100,
          'createdAt': Timestamp.now(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Signs in existing user
  Future<User?> signIn(String email, String password) async {

    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // Signs out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}