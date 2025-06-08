import 'chat_participant.dart';
import 'chat_message.dart';

class ChatRoom {
  final String id;
  final String name;
  final bool isGroup;
  final bool isClosed;
  DateTime? closedOn;
  final bool isPublic;

  ChatRoom({
    required this.id,
    required this.name,
    required this.isPublic,
    required this.isGroup,
    required this.isClosed
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'],
      isPublic: json['isPublic'],
      isGroup: json['isGroup'],
      isClosed: json['isClosed']
    );
  }
}