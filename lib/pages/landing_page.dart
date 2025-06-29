import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // Using 'final' is good practice if the instance doesn't change.
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  // Renamed for clarity
  Future<void> _checkSessionAndNavigate() async {
    try {
      final expiryStr = await storage.read(key: 'expiry');
      if (expiryStr != null) {
        // Use tryParse for safety. It returns null instead of throwing an error.
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null && DateTime.now().isBefore(expiry)) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // This logic is good. Let's ensure the user document exists.
            final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
            final snapshot = await doc.get();

            if (!snapshot.exists) {
              await doc.set({
                'uid': user.uid,
                'email': user.email,
                'displayName': user.displayName ?? user.email?.split('@').first ?? 'User', // A safer fallback for displayName
              });
            }
          }

          // BEST PRACTICE: Check if the widget is still mounted before using its context.
          if (!context.mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
          return; // Exit the function
        }
      }

      // If we reach here, it means no valid session was found.
      // Clean up just in case.
      await FirebaseAuth.instance.signOut();
      await storage.deleteAll(); // Clear out old/invalid data

    } catch (e) {
      // If ANY error occurs (storage read, firestore, etc.), fail safely.
      debugPrint('An error occurred during session check: $e');
      await FirebaseAuth.instance.signOut();
      await storage.deleteAll();
    }

    // Fallback navigation to the login page.
    // Also check if mounted here as a final safety measure.
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    // A loading indicator is perfect for this page.
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}