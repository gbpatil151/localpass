import 'package:flutter/material.dart';
import 'package:localpass/screens/signup_screen.dart';
import 'package:localpass/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // NEW: Get instance of AuthService
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
                // NEW: Call Login Logic
                String email = _emailController.text.trim();
                String password = _passwordController.text.trim();

                if (email.isNotEmpty && password.isNotEmpty) {
                  var user = await _authService.signIn(email, password);
                  if (user == null) {
                    // TODO: Show an error (e.g., "Invalid credentials")
                    print("Login failed");
                  }
                  // If login is successful, the AuthWrapper will
                  // automatically handle navigation to HomeScreen.
                }
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to Sign Up Screen
                // NEW: Navigate to Sign Up Screen
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