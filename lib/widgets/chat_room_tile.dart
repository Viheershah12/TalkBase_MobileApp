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

  Widget _buildFallbackIcon(BuildContext context) {
    return Icon(
      Icons.group,
      size: 28,
      color: Theme.of(context).primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final int unreadCount = (currentUser != null && chatRoom.unreadCounts.containsKey(currentUser.uid))
        ? chatRoom.unreadCounts[currentUser.uid]!
        : 0;

    final bool hasUnread = unreadCount > 0;
    final theme = Theme.of(context);
    final accentColor = theme.primaryColor;
    final mutedColor = theme.colorScheme.onSurface.withOpacity(0.7);
    final bool hasValidPhotoUrl = chatRoom.groupIconUrl != null && chatRoom.groupIconUrl!.isNotEmpty;

    return Card(
      elevation: hasUnread ? 4 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.surfaceVariant,
          child: hasValidPhotoUrl ? ClipOval(
            child: Image.network(
              chatRoom.groupIconUrl!,
              fit: BoxFit.cover,
              width: 56, // Diameter (2 * radius)
              height: 56,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackIcon(context);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ) : _buildFallbackIcon(context),
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
}