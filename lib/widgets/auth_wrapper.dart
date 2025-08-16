// lib/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkbase/pages/auth/login_page.dart';

import '../pages/home.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. While waiting for connection, show a loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. If the snapshot has data, a user is logged in
        if (snapshot.hasData) {
          return const HomePage(); // Go to your main app page
        }

        // 3. If no data, the user is not logged in
        return const LoginPage(); // Go to the login page
      },
    );
  }
}