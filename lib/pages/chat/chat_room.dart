import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/modern_chat_bubble.dart';

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
  bool _showSendButton = false;
  String _participantNames = 'Loading...';
  ChatRoom? _chatRoom;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRoomData();
    _messageController.addListener(() {
      setState(() {
        _showSendButton = _messageController.text.trim().isNotEmpty;
      });
    });

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
        type: MessageType.text
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

  Future<void> _loadChatRoomData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('ChatRoom').doc(widget.chatRoomId).get();
      if (doc.exists) {
        final chatRoom = ChatRoom.fromMap(doc.data()!);

        // Fetch participant names
        final names = await _fetchParticipantNames(chatRoom.participants);

        // Use setState to update the UI with all the new data
        if (mounted) {
          setState(() {
            _chatRoom = chatRoom;
            _participantNames = names;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading chat room data: $e");
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _fetchParticipantNames(List<String> participantUids) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return '';
    }

    // Fetch user documents for the other participants
    final List<String> names = [];
    for (String uid in participantUids) {
      if (uid == currentUser.uid) {
        names.add('You');
      } else {
        // Otherwise, fetch the other user's name from Firestore
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists) {
            names.add(userDoc.data()?['displayName'] ?? 'A User');
          }
        } catch (e) {
          debugPrint("Error fetching user name for UID $uid: $e");
          // Add a placeholder if a user lookup fails
          names.add('A User');
        }
      }
    }

    names.sort((a, b) {
      if (a == 'You') return -1;
      if (b == 'You') return 1;
      return a.compareTo(b);
    });

    return names.join(', ');
  }

  Future<void> _setGroupPicture() async {
    final picker = ImagePicker();

    // 1. PICK THE IMAGE
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile == null) {
      // User canceled the image selection
      return;
    }

    // Show a loading indicator
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading group icon...')),
    );

    try {
      final file = File(pickedFile.path);

      // 2. UPLOAD TO FIREBASE STORAGE
      // Create a reference to the file in Cloud Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('group_icons') // A dedicated folder for group icons
          .child('${widget.chatRoomId}.jpg');

      // Upload the file
      await ref.putFile(file);

      // 3. GET DOWNLOAD URL & UPDATE FIRESTORE
      final imageUrl = await ref.getDownloadURL();

      // Update the ChatRoom document in Firestore
      await FirebaseFirestore.instance
          .collection('ChatRoom')
          .doc(widget.chatRoomId)
          .update({'groupIconUrl': imageUrl});

      await _loadChatRoomData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group icon updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating icon: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('ChatRoom').doc(widget.chatRoomId).get(),
      builder: (context, chatRoomSnapshot) {
        if (!chatRoomSnapshot.hasData) {
          return const Scaffold(appBar: null, body: Center(child: CircularProgressIndicator()));
        }

        final chatRoom = ChatRoom.fromMap(chatRoomSnapshot.data!.data() as Map<String, dynamic>);
        final currentUser = FirebaseAuth.instance.currentUser;

        if (_participantNames == 'Loading...') {
          _fetchAndSetParticipantNames(chatRoom.participants);
        }

        return Scaffold(
          appBar: _buildDynamicAppBar(context, chatRoom, _participantNames),
          body: Container(
            // decoration: BoxDecoration(
            //   image: DecorationImage(
            //     image: const AssetImage('assets/chat_background.png'),
            //     fit: BoxFit.cover,
            //     colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.8), BlendMode.dstATop),
            //   ),
            // ),
            child: Column(
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

                          return ModernChatBubble(
                            message: msg,
                            isMe: isMe,
                            isGroupChat: chatRoom.participants.length > 2,
                          );
                        },
                      );
                    },
                  ),
                ),

                _buildInputComposer(), // Use the new enhanced input composer
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildDynamicAppBar(BuildContext context, ChatRoom chatRoom, String participantNames) {
    final bool hasValidPhotoUrl = chatRoom.groupIconUrl != null && chatRoom.groupIconUrl!.isNotEmpty;

    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      title: Row(
        children: [
          InkWell(
            onTap: _setGroupPicture, // Trigger the method on tap
            child: CircleAvatar(
              radius: 20,
              backgroundImage: hasValidPhotoUrl
                  ? NetworkImage(chatRoom.groupIconUrl!)
                  : null,
              child: !hasValidPhotoUrl
                  ? const Icon(Icons.group, size: 22)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chatRoom.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (participantNames.isNotEmpty)
                  Text(
                    participantNames,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.call), onPressed: () {}),
        // You could also put the change picture logic in this menu
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  Future<void> _fetchAndSetParticipantNames(List<String> participantUids) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Fetch user documents for the other participants
    final List<String> names = [];
    for (String uid in participantUids) {
      if (uid == currentUser.uid) {
        names.add('You');
      } else {
        // Otherwise, fetch the other user's name from Firestore
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists) {
            names.add(userDoc.data()?['displayName'] ?? 'A User');
          }
        } catch (e) {
          debugPrint("Error fetching user name for UID $uid: $e");
          // Add a placeholder if a user lookup fails
          names.add('A User');
        }
      }
    }

    names.sort((a, b) {
      if (a == 'You') return -1;
      if (b == 'You') return 1;
      return a.compareTo(b);
    });

    // Update the state with the comma-separated names
    if (mounted) {
      setState(() {
        _participantNames = names.join(', ');
      });
    }
  }

  Widget _buildInputComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // SCOPE: Attachment Button
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.grey[600]),
            onPressed: () {
              // TODO: Implement attachment picking logic
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              keyboardType: TextInputType.multiline,
              maxLines: null, // Allows the text field to grow
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // NEW: Send button appears conditionally
          if (_showSendButton)
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.mic, color: Colors.grey[600]),
              onPressed: () {
                // TODO: Implement voice message logic
              },
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
