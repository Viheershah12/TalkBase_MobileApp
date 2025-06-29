import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String senderName;
  final DateTime timestamp;
  final bool isMe;
  final bool isGroupChat; // We need to know if this is a group chat

  const ChatBubble({
    super.key,
    required this.message,
    required this.senderName,
    required this.timestamp,
    required this.isMe,
    required this.isGroupChat,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors and alignment based on who sent the message
    final theme = Theme.of(context);
    final bubbleColor = isMe ? theme.primaryColor.withOpacity(0.9) : Colors.grey[200];
    final textColor = isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // --- KEY CHANGE 1: Conditional Name Display ---
            // Only show the sender's name if it's a group chat AND not my message.
            if (isGroupChat && !isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor, // Use a distinct color for the name
                    fontSize: 13,
                  ),
                ),
              ),

            // --- Message Text ---
            Text(
              message,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 5),

            // --- KEY CHANGE 2: Timestamp Alignment and Style ---
            Text(
              DateFormat('hh:mm a').format(timestamp), // Assumes you have the 'intl' package
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white.withOpacity(0.7) : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}