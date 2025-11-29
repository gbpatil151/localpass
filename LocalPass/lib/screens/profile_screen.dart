import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localpass/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({Key? key}) : super(key: key);

  final AuthService _authService = AuthService();
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) return Center(child: Text("Not Logged In"));

    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var userData = snapshot.data!.data() as Map<String, dynamic>?;
          int balance = userData?['walletBalance'] ?? 0;
          String email = userData?['email'] ?? user!.email;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                ),
                SizedBox(height: 20),
                Center(child: Text(email, style: TextStyle(fontSize: 18, color: Colors.grey))),
                SizedBox(height: 40),

                // WALLET CARD
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Wallet Balance', style: TextStyle(fontSize: 18)),
                        Text(
                            '\$$balance',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800])
                        ),
                      ],
                    ),
                  ),
                ),

                Spacer(),

                // LOGOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      _authService.signOut();
                    },
                    child: Text('Log Out', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}