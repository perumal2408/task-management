import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart'; // Main task tracking page
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Task Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SignInScreen(),
      routes: {
        '/home': (context) => HomePage(),
        '/login': (context) => SignInScreen(),
      },
    );
  }
}

class SignInScreen extends StatelessWidget {
  Future<bool> isEmailAllowed(String email) async {
    try {
      // Fetching allowed emails from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('allowedEmails').get();
      List<String> allowedEmails = snapshot.docs.map((doc) => doc['email'] as String).toList();
      return allowedEmails.contains(email);
    } catch (e) {
      print('Error fetching allowed emails: $e');
      return false;
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      // Check if the signed-in email is allowed
      if (user != null && await isEmailAllowed(user.email!)) {
        // If email is allowed, navigate to HomePage
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Sign out and show error if the email is not allowed
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your email is not authorized to use this app.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => signInWithGoogle(context),
          child: Text('Sign in with Google'),
        ),
      ),
    );
  }
}
