import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../widgets/chat_bubble.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatRoomId;

  const ChatRoomPage({super.key, required this.chatRoomId});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final bool isGroupChat = true;

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  void _sendMessage() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final newMessage = ChatMessage(
        id: '',
        senderId: user.uid,
        senderName: user.displayName ?? '',
        message: msg,
        timestamp: DateTime.now(),
      );

      await sendMessage(widget.chatRoomId, newMessage);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _markAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final chatRoomRef = FirebaseFirestore.instance.collection('ChatRoom').doc(widget.chatRoomId);

      // Use dot notation to update a specific field in the map
      await chatRoomRef.update({
        'unreadCounts.${user.uid}': 0
      });
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Room'),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[50], // A slightly off-white background
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: getMessages(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No messages yet. Say hi!"));
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser?.uid;

                    // --- Using the new, cleaner ChatBubble widget ---
                    return ChatBubble(
                      message: msg.message,
                      senderName: msg.senderName,
                      timestamp: msg.timestamp,
                      isMe: isMe,
                      isGroupChat: isGroupChat, // Pass the flag here
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> sendMessage(String chatRoomId, ChatMessage message) async {
  await FirebaseFirestore.instance
      .collection('ChatRoom')
      .doc(chatRoomId)
      .collection('messages')
      .add(message.toMap());
}

Stream<List<ChatMessage>> getMessages(String chatRoomId) {
  return FirebaseFirestore.instance
      .collection('ChatRoom')
      .doc(chatRoomId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
      .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
      .toList());
}
