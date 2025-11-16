import 'package:flutter/material.dart';
import 'package:localpass/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // We'll add a name controller later for the user's profile
  // NEW: Get instance of AuthService
  final AuthService _authService = AuthService();
  // ... rest of the class

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password (min. 6 chars)'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              // ... inside the ElevatedButton's onPressed ...
              onPressed: () async {
                // NEW: Call Sign Up Logic
                String email = _emailController.text.trim();
                String password = _passwordController.text.trim();

                if (email.isNotEmpty && password.isNotEmpty) {
                  var user = await _authService.signUp(email, password);
                  if (user != null) {
                    // Sign up was successful!
                    // The AuthWrapper will automatically see the new user
                    // and send them to the HomeScreen.
                    // We just need to pop this screen off.
                    Navigator.of(context).pop();
                  } else {
                    // TODO: Show an error message (e.g., "Password too weak")
                    print("Sign up failed");
                  }
                }
              },
              child: Text('Sign Up'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate back to Login Screen
                // NEW: Navigate back to Login Screen
                Navigator.of(context).pop();
              },
              child: Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}