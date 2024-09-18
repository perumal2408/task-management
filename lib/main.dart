import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart'; // Import the AuthService file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Sign-In',
      home: SignInScreen(), // Set SignInScreen as the home screen
    );
  }
}

class SignInScreen extends StatelessWidget {
  final AuthService _authService = AuthService(); // Instance of AuthService

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Sign-In')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final user = await _authService.signInWithGoogle(); // Call Google Sign-In
                if (user != null) {
                  // If sign-in is successful, navigate to WelcomeScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WelcomeScreen(user),
                    ),
                  );
                }
              },
              child: Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  final User user; // User object passed from SignInScreen

  WelcomeScreen(this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              AuthService().signOut(); // Call sign out
              Navigator.pop(context); // Return to sign-in screen
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(user.photoURL ?? ''), // User profile image
              radius: 40,
            ),
            SizedBox(height: 10),
            Text('Welcome, ${user.displayName}'), // User display name
            Text('Email: ${user.email}'), // User email
          ],
        ),
      ),
    );
  }
}
