import 'package:flutter/material.dart';
import '../models/chat_room.dart';

class ChatRoomTile extends StatelessWidget {
  final ChatRoom chatRoom;

  const ChatRoomTile({super.key, required this.chatRoom});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: chatRoom.isGroup ? Colors.purple : Colors.blue,
          child: Icon(
            chatRoom.isGroup ? Icons.group : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(chatRoom.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(chatRoom.isGroup ? 'Group chat' : 'Private chat'),
        trailing: chatRoom.isClosed ? const Icon(Icons.lock, color: Colors.redAccent) : null,
        onTap: () {
          // TODO: Navigate to chat detail page
        },
      ),
    );
  }
}
