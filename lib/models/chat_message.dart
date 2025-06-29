import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    MessageType messageTypeFromString(String? typeStr) {
      if (typeStr == 'MessageType.image') {
        return MessageType.image;
      }
      return MessageType.text;
    }

    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: messageTypeFromString(map['type']), // Use the helper function here
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp,
      'type': type.toString()
    };
  }
}