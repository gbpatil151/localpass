import 'package:flutter/material.dart';
// 1. Import your AuthService
import 'package:localpass/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  // 2. Get an instance of the AuthService
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LocalPass Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            // 3. Call the signOut method
            onPressed: () {
              _authService.signOut();
              // The AuthWrapper will automatically handle
              // navigation back to the LoginScreen.
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome! You are logged in.'),
      ),
    );
  }
}