import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> leaveChatRoom({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      final chatRoomRef = _firestore.collection('ChatRoom').doc(chatRoomId);

      // Important: Check if this is the last participant
      final doc = await chatRoomRef.get();
      if (doc.exists) {
        final participants = List<String>.from(doc.data()?['participants'] ?? []);

        if (participants.length == 1 && participants.contains(userId)) {
          // If the last participant is leaving, delete the whole chat room.
          await chatRoomRef.delete();
          print("Last participant left. Chat room deleted.");
        } else {
          // Otherwise, just remove the user from the participants list.
          await chatRoomRef.update({
            'participants': FieldValue.arrayRemove([userId]),
            'updatedBy': userId, // Keep track of who made the last change
            'updatedOn': FieldValue.serverTimestamp(),
          });
          print("User $userId left chat room $chatRoomId.");
        }
      }
    } catch (e) {
      // Handle any errors, e.g., show a snackbar
      print("Error leaving chat room: $e");
      throw Exception("Could not leave the chat room. Please try again.");
    }
  }
}