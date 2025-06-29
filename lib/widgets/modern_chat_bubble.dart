import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

class ModernChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isGroupChat;

  const ModernChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isGroupChat,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(colors: [Colors.deepPurple, Colors.purpleAccent])
              : null,
          color: !isMe ? Colors.white : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          // Control the alignment of all children from the Column itself.
          // This makes the Column's width wrap its content.
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // The sender's name will still be left-aligned within its own space
            // because the Column's crossAxisAlignment is 'start' for other users.
            if (isGroupChat && !isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  message.senderName,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 13),
                ),
              ),

            _buildMessageContent(),
            const SizedBox(height: 5),

            // --- The Align widget is REMOVED from around the Text ---
            // The Column's crossAxisAlignment now handles the alignment.
            Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(fontSize: 12, color: isMe ? Colors.white70 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.image:
      // SCOPE: Attachment UI
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(message.message, fit: BoxFit.cover), // message contains the image URL
        );
      case MessageType.text:
      default:
        return Text(
          message.message,
          style: TextStyle(fontSize: 16, color: isMe ? Colors.white : Colors.black87),
        );
    }
  }
}