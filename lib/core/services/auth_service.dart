import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      var cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // Future<User?> registerWithEmail(String email, String password) async {
  //   try {
  //     UserCredential cred = await _auth.createUserWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //     return cred.user;
  //   } catch (e) {
  //     print(e);
  //     return null;
  //   }
  // }

  Future<User?> registerWithEmail(String email, String password, String firstName, String lastName) async {
    try {
      // 1. Create the user
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = cred.user;

      // 2. Update the displayName
      if (user != null) {
        // Combine first and last name for the display name
        String displayName = '$firstName $lastName';
        await user.updateDisplayName(displayName);

        // Optional: reload the user to get the updated info
        await user.reload();
        user = _auth.currentUser;
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      print('Firebase Auth Exception: ${e.message}');
      return null;
    } catch (e) {
      print('An unexpected error occurred: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendOtp(String phoneNumber, Function(String, int?) codeSent) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Verification failed: $e");
      },
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<User?> verifyOtp(String verificationId, String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    UserCredential cred = await _auth.signInWithCredential(credential);
    return cred.user;
  }

  User? get currentUser => _auth.currentUser;
}
