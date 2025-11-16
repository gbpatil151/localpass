import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import your new files
import 'package:localpass/services/auth_service.dart';
import 'package:localpass/screens/home_screen.dart';
import 'package:localpass/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalPass',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Use the AuthWrapper as the home
      home: AuthWrapper(authService: _authService),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final AuthService authService;

  const AuthWrapper({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to the auth state stream from AuthService
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Check if the stream is still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Check if we have data (a user)
        if (snapshot.hasData) {
          // User is logged in
          return HomeScreen();
        } else {
          // User is logged out
          return LoginScreen();
        }
      },
    );
  }
}