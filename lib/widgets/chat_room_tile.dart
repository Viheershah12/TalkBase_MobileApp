import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_room.dart';
import '../pages/chat/chat_room.dart';

class ChatRoomTile extends StatelessWidget {
  final ChatRoom chatRoom;

  const ChatRoomTile({
    super.key,
    required this.chatRoom
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final int unreadCount = (currentUser != null && chatRoom.unreadCounts.containsKey(currentUser.uid))
        ? chatRoom.unreadCounts[currentUser.uid]!
        : 0;

    final bool hasUnread = unreadCount > 0;
    final theme = Theme.of(context);
    final accentColor = theme.primaryColor;
    final mutedColor = Colors.grey[600];

    return Card(
      elevation: hasUnread ? 4 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: accentColor.withOpacity(0.1),
        ),
        title: Text(
          chatRoom.name,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
            fontSize: 17,
          ),
        ),
        subtitle: Text(
          '${chatRoom.participants.length} Participants',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: mutedColor,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Display the timestamp, styled differently if unread
            if (chatRoom.updatedOn != null)
              Text(
                DateFormat('hh:mm a').format(chatRoom.updatedOn!),
                style: TextStyle(
                  fontSize: 12,
                  color: hasUnread ? accentColor : mutedColor,
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            const SizedBox(height: 5),

            if (hasUnread)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accentColor, // Use your app's theme color
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              // If there are no unread messages, show an empty box
              // to keep the alignment consistent with other tiles.
              const SizedBox(height: 24, width: 24),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomPage(chatRoomId: chatRoom.id),
            ),
          );
        }
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final accentColor = theme.primaryColor;
  //   final mutedColor = Colors.grey[600];
  //
  //   // Determine if the chat is a group or individual based on participants
  //   final bool isGroupChat = chatRoom.participants.length > 2;
  //
  //   return Card(
  //     elevation: 2,
  //     margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //     child: ListTile(
  //       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //       leading: CircleAvatar(
  //         radius: 28,
  //         backgroundColor: accentColor.withOpacity(0.1),
  //         child: Text(
  //           // Use the first letter of the name for the avatar
  //           chatRoom.name.isNotEmpty ? chatRoom.name[0].toUpperCase() : '?',
  //           style: TextStyle(
  //             fontSize: 22,
  //             fontWeight: FontWeight.bold,
  //             color: accentColor,
  //           ),
  //         ),
  //       ),
  //       title: Text(
  //         chatRoom.name,
  //         style: const TextStyle(
  //           fontWeight: FontWeight.w600,
  //           fontSize: 17,
  //         ),
  //       ),
  //       // Use the participant count as the subtitle
  //       subtitle: Text(
  //         '${chatRoom.participants.length} Participants',
  //         maxLines: 1,
  //         overflow: TextOverflow.ellipsis,
  //         style: TextStyle(
  //           fontSize: 14,
  //           color: mutedColor,
  //         ),
  //       ),
  //       // Use `updatedOn` for the timestamp
  //       trailing: chatRoom.updatedOn != null
  //           ? Text(
  //         DateFormat('hh:mm a').format(chatRoom.updatedOn!),
  //         style: TextStyle(
  //           fontSize: 12,
  //           color: mutedColor,
  //         ),
  //       )
  //           : null, // If there's no date, show nothing
  //       onTap: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => ChatRoomPage(chatRoomId: chatRoom.id),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
}