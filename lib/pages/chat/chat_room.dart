import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/chat_service.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../widgets/modern_chat_bubble.dart';
import 'call_screen.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatRoomId;

  const ChatRoomPage({super.key, required this.chatRoomId});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSendButton = false;
  String _participantNames = 'Loading...';
  ChatRoom? _chatRoom;
  bool _isLoading = true;
  String? _otherUserUid;

  @override
  void initState() {
    super.initState();
    _loadChatRoomData();
    _messageController.addListener(() {
      if (mounted) {
        setState(() {
          _showSendButton = _messageController.text.trim().isNotEmpty;
        });
      }
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
        type: MessageType.text,
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
      await chatRoomRef.update({'unreadCounts.${user.uid}': 0});
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
  }

  Future<void> _loadChatRoomData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('ChatRoom').doc(widget.chatRoomId).get();
      if (doc.exists) {
        final chatRoom = ChatRoom.fromMap(doc.data()!);
        final names = await _fetchParticipantNames(chatRoom.participants);

        String? otherUser;
        final currentUser = FirebaseAuth.instance.currentUser;
        if (chatRoom.participants.length == 2 && currentUser != null) {
          otherUser = chatRoom.participants.firstWhere((uid) => uid != currentUser.uid);
        }

        if (mounted) {
          setState(() {
            _chatRoom = chatRoom;
            _participantNames = names;
            _otherUserUid = otherUser; // Save the UID
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
    if (currentUser == null) return '';

    final List<String> names = [];
    for (String uid in participantUids) {
      if (uid == currentUser.uid) {
        names.add('You');
      } else {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists) {
            names.add(userDoc.data()?['displayName'] ?? 'A User');
          }
        } catch (e) {
          debugPrint("Error fetching user name for UID $uid: $e");
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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading group icon...')),
    );

    try {
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref().child('group_icons').child('${widget.chatRoomId}.jpg');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('ChatRoom').doc(widget.chatRoomId).update({'groupIconUrl': imageUrl});
      await _loadChatRoomData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group icon updated successfully!'), backgroundColor: Colors.green),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating icon: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_chatRoom == null) {
      return Scaffold(appBar: AppBar(title: const Text("Error")), body: const Center(child: Text("Could not load chat room.")));
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: _buildDynamicAppBar(context, _chatRoom!, _participantNames),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: getMessages(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No messages yet. Say hi!"));
                }

                final messages = snapshot.data!;
                // Scroll to bottom after the frame is built
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

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
                      isGroupChat: _chatRoom!.participants.length > 2,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputComposer(),
        ],
      ),
    );
  }

  AppBar _buildDynamicAppBar(BuildContext context, ChatRoom chatRoom, String participantNames) {
    final theme = Theme.of(context);
    final hasValidPhotoUrl = chatRoom.groupIconUrl != null && chatRoom.groupIconUrl!.isNotEmpty;

    return AppBar(
      elevation: 1,
      // Use theme colors for AppBar
      backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
      foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
      title: Row(
        children: [
          InkWell(
            onTap: _setGroupPicture,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: hasValidPhotoUrl ? NetworkImage(chatRoom.groupIconUrl!) : null,
              child: !hasValidPhotoUrl ? Icon(Icons.group, size: 22, color: theme.colorScheme.onPrimaryContainer) : null,
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
                    // Use a theme color for the subtitle
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // IconButton(
        //   icon: const Icon(Icons.call),
        //   onPressed: _otherUserUid == null
        //       ? null
        //       : () async {
        //     final currentUser = FirebaseAuth.instance.currentUser;
        //     if (currentUser == null) return;
        //
        //     // --- Show a loading dialog for better UX ---
        //     showDialog(
        //       context: context,
        //       barrierDismissible: false,
        //       builder: (context) => const Center(child: CircularProgressIndicator()),
        //     );
        //
        //     try {
        //       // --- STEP 1: Create the call document in Firestore ---
        //
        //       // Let Firestore generate a unique ID for the new call document
        //       final callDocRef = FirebaseFirestore.instance.collection('calls').doc();
        //
        //       // The channelName is now just a field inside the document
        //       final String channelName = getUniqueChannelName(currentUser.uid, _otherUserUid!);
        //
        //       await callDocRef.set({
        //         // Save the auto-generated ID inside the document for easy access
        //         'callId': callDocRef.id,
        //         'callerId': currentUser.uid,
        //         'callerName': currentUser.displayName ?? 'A User',
        //         'receiverId': _otherUserUid!,
        //         'channelName': channelName, // Store the channel name here
        //         'status': 'ringing',
        //         'createdOn': FieldValue.serverTimestamp(),
        //       });
        //
        //
        //       // --- STEP 2: Fetch the token and navigate ---
        //       final token = await _fetchAgoraToken(channelName);
        //       if (mounted) Navigator.pop(context); // Dismiss loading dialog
        //
        //       if (mounted) {
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //             builder: (context) => CallScreen(
        //               channelName: channelName,
        //               token: token,
        //             ),
        //           ),
        //         );
        //       }
        //     } catch (e) {
        //       // Dismiss loading dialog and show error
        //       if (mounted) Navigator.pop(context);
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(content: Text('Error starting call: ${e.toString()}')),
        //       );
        //     }
        //   },
        // ),
        PopupMenuButton<String>(
          offset: const Offset(0, 40),
          onSelected: (value) {
            // Handle the user's choice based on the value
            switch (value) {
              case 'chat_details':
                // TODO: Navigate to chat details/members screen
                print('Navigate to chat details');
                break;
              case 'mute_notifications':
                // TODO: Implement mute/unmute logic
                print('Mute notifications');
                break;
              case 'leave_chat':
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Leave Chat?'),
                      content: const Text('Are you sure you want to leave this chat room?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(); // Close the dialog
                          },
                        ),
                        TextButton(
                          child: Text('Leave', style: TextStyle(color: Colors.red)),
                          onPressed: () async {
                            Navigator.of(dialogContext).pop(); // Close the dialog

                            // Get current user's ID
                            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                            if (currentUserId != null) {
                              try {
                                // Call the leave chat function
                                await ChatService().leaveChatRoom(
                                  chatRoomId: chatRoom.id,
                                  userId: currentUserId,
                                );

                                // Navigate back or show a success message
                                Navigator.of(context).pop(); // Go back from the chat screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("You have left the chat.")),
                                );

                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'chat_details',
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Chat Details'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'mute_notifications',
              child: ListTile(
                leading: Icon(Icons.notifications_off_outlined),
                title: Text('Mute Notifications'),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'leave_chat',
              child: ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.red),
                title: Text('Leave Chat', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  String getUniqueChannelName(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join("_");
  }

  /// Fetches a secure Agora token from the backend Firebase Cloud Function.
  Future<String> _fetchAgoraToken(String channelName) async {
    try {
      // Get an instance of the Firebase Functions
      final functions = FirebaseFunctions.instance;

      // Get a reference to the specific callable function by its name
      final callable = functions.httpsCallable('generateAgoraToken');

      // Call the function, passing the channelName as a parameter
      final response = await callable.call<Map<String, dynamic>>({
        'channelName': channelName,
      });

      // Extract the token from the response data
      final token = response.data['token'];

      if (token == null) {
        // Throw an exception if the token is missing from the response
        throw Exception('Token received from server was null.');
      }

      return token;
    } on FirebaseFunctionsException catch (e) {
      // Handle specific Firebase Functions errors
      print("FirebaseFunctionsException: ${e.message}");
      throw Exception('Failed to fetch Agora token. Please check server logs.');
    } catch (e) {
      // Handle any other generic errors
      print("Error fetching Agora token: $e");
      throw Exception('An unknown error occurred while starting the call.');
    }
  }

  Widget _buildInputComposer() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      // Use a theme color for the container background
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                // Use a theme color for the text field
                fillColor: theme.colorScheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_showSendButton)
            CircleAvatar(
              backgroundColor: theme.primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.mic, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              onPressed: () {},
            ),
        ],
      ),
    );
  }
}

// Helper functions (sendMessage, getMessages) remain the same
Future<void> sendMessage(String chatRoomId, ChatMessage message) async {
  final docRef = FirebaseFirestore.instance.collection('ChatRoom').doc(chatRoomId);
  await docRef.collection('messages').add(message.toMap());
  await docRef.update({'updatedOn': message.timestamp, 'updatedBy': message.senderId});
}

Stream<List<ChatMessage>> getMessages(String chatRoomId) {
  return FirebaseFirestore.instance
      .collection('ChatRoom')
      .doc(chatRoomId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data(), doc.id)).toList());
}
