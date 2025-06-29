import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission from the user
    await _fcm.requestPermission();

    // Get the FCM token for this device
    final fcmToken = await _fcm.getToken();
    debugPrint("FCM Token: $fcmToken");

    // Save the token to the current user's document in Firestore
    if (fcmToken != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        // Save the token in an array, as a user can have multiple devices
        await userDoc.update({
          'fcmTokens': FieldValue.arrayUnion([fcmToken])
        });
      }
    }
  }
}