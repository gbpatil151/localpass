import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import your new screens and services
import 'package:localpass/services/auth_service.dart';
import 'package:localpass/screens/login_screen.dart';
import 'package:localpass/screens/main_screen.dart';

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          // User is logged in: SHOW THE MAIN NAVIGATION SCREEN
          return const MainScreen();
        } else {
          // User is logged out: SHOW THE LOGIN SCREEN
          return const LoginScreen();
        }
      },
    );
  }
}