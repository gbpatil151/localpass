import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localpass/services/auth_service.dart';
import 'package:localpass/screens/add_event_screen.dart';

// Profile screen showing user info, wallet balance, and admin options
class ProfileScreen extends StatelessWidget {
  ProfileScreen({Key? key}) : super(key: key);

  final AuthService _authService = AuthService();
  final User? user = FirebaseAuth.instance.currentUser;

  final String adminEmail = "admin@localpass.com";

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("User data not found."));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>?;
          int balance = userData?['walletBalance'] ?? 0;
          String displayName = userData?['displayName'] ?? 'User';
          String email = userData?['email'] ?? user!.email!;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue[100],
                        child: Icon(Icons.person,
                            size: 50, color: Colors.blue[800]),
                      ),
                      SizedBox(height: 16),
                      Text(displayName,
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(email,
                          style:
                          TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                ),
                SizedBox(height: 40),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet,
                                color: Colors.blue[800]),
                            SizedBox(width: 12),
                            Text('Wallet Balance',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Text('\$$balance',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700])),
                      ],
                    ),
                  ),
                ),
                Spacer(),
                // Show admin button only for admin user
                if (email == adminEmail) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.add_circle_outline, color: Colors.white),
                      label: Text('Admin: Add Event',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddEventScreen()));
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.red.withOpacity(0.5))),
                    ),
                    onPressed: () {
                      _authService.signOut();
                    },
                    child: Text('Log Out', style: TextStyle(fontSize: 16)),
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