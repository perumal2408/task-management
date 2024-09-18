import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // Define the list of allowed email IDs
  final List<String> allowedEmails = ['perumal.laxman@thehindu.co.in', 'jayashree.manickavel@gmail.com'];

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

      // Check if the signed-in email is in the allowed list
      if (user != null && allowedEmails.contains(user.email)) {
        // If the email is allowed, navigate to the HomePage
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // If the email is not allowed, sign out and show error
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
