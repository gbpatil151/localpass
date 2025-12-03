import 'package:firebase_auth/firebase_auth.dart'; // Import this for Exception handling
import 'package:flutter/material.dart';
import 'package:localpass/services/auth_service.dart';
import 'package:localpass/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
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
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String email = _emailController.text.trim();
                String password = _passwordController.text.trim();

                if (email.isNotEmpty && password.isNotEmpty) {
                  try {
                    // Try to sign in
                    await _authService.signIn(email, password);
                    // If successful, AuthWrapper handles navigation
                  } on FirebaseAuthException catch (e) {
                    // HANDLE SPECIFIC ERRORS HERE
                    String errorMessage = 'Login failed. Please try again.';

                    if (e.code == 'user-not-found') {
                      errorMessage = 'No user found for that email.';
                    } else if (e.code == 'wrong-password') { // Note: Firebase sometimes uses 'invalid-credential' now
                      errorMessage = 'Wrong password provided.';
                    } else if (e.code == 'invalid-credential') {
                      errorMessage = 'Invalid email or password.';
                    } else if (e.code == 'invalid-email') {
                      errorMessage = 'The email address is badly formatted.';
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch (e) {
                    // Handle generic errors
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              child: Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}