import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/chat_room.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/chat_room_tile.dart';

class ChatRoomListPage extends StatefulWidget{
  const ChatRoomListPage({super.key});

  @override
  State<ChatRoomListPage> createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends State<ChatRoomListPage>{
  late final Stream<List<ChatRoom>> _chatRoomsStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _initializeStream();
  }

  void _initializeStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _chatRoomsStream = FirebaseFirestore.instance
          .collection('ChatRoom')
          .where('participants', arrayContains: user.uid)
          .orderBy('updatedOn', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.data()))
          .toList());

      // Listen to the first event to turn off the initial loader
      _chatRoomsStream.first.then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } else {
      _chatRoomsStream = Stream.value([]);
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 2. CREATE a real refresh handler
  Future<void> _handleRefresh() async {
    // Set loading to true to show the shimmer
    setState(() {
      _isLoading = true;
    });

    // In a stream, the data will update automatically. We mainly add a delay
    // here for a better user experience, making the refresh feel tangible.
    // The shimmer will show for at least this duration.
    await Future.delayed(const Duration(milliseconds: 1500));

    // After the "refresh", set loading back to false
    if(mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: MyAwesomeAppBar(title: "Chats", hasBackButton: false),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateChatRoomDialog(context),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(16.0)), // FAB shape
          ),
          child: const Center(
            child: Icon(Icons.add_outlined, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // Helper method to keep the build method clean
  Widget _buildBody() {
    // If our manual refresh is active, show the shimmer.
    if (_isLoading) {
      return _buildShimmerEffect();
    }

    // Otherwise, use the StreamBuilder as before.
    return StreamBuilder<List<ChatRoom>>(
      stream: _chatRoomsStream,
      builder: (context, snapshot) {
        // We no longer need the ConnectionState.waiting check here,
        // because our _isLoading flag handles the initial load.
        if (snapshot.hasError) {
          return Center(child: Text("An error occurred: ${snapshot.error}"));
        }

        final chatRooms = snapshot.data;
        if (chatRooms == null || chatRooms.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            return ChatRoomTile(chatRoom: chatRooms[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    // Use a ListView to ensure the RefreshIndicator still works
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Use MediaQuery to center content dynamically on any screen
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(
          Icons.forum_outlined,
          size: 100,
          color: Colors.grey,
        ),
        const SizedBox(height: 20),
        const Text(
          "No Chats Yet",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Tap the '+' button below to start a new conversation.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      itemCount: 8, // Show 8 shimmer items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            leading: const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
            ),
            title: Container(
              height: 16,
              width: 150,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 14,
              width: 200,
              color: Colors.white,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 12,
                  width: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  width: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateChatRoomDialog(BuildContext context) {
    final TextEditingController _nameController = TextEditingController();
    List<String> selectedUserIds = [];
    List<Map<String, dynamic>> users = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Center(
                child: Text("New Chat Room", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Room Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.chat),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select Participants",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder(
                      future: FirebaseFirestore.instance.collection('users').get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          );
                        }

                        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                        final docs = snapshot.data!.docs.where((doc) => doc['uid'] != currentUserId);
                        users = docs.map((doc) => doc.data()).toList().cast<Map<String, dynamic>>();

                        if (users.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("No users found."),
                          );
                        }

                        return Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final userId = user['uid'];
                              final displayName = user['displayName'].toString().isNotEmpty
                                  ? user['displayName']
                                  : user['email'];

                              return CheckboxListTile(
                                title: Text(displayName),
                                value: selectedUserIds.contains(userId),
                                onChanged: (bool? selected) {
                                  setState(() {
                                    if (selected == true) {
                                      selectedUserIds.add(userId);
                                    } else {
                                      selectedUserIds.remove(userId);
                                    }
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text.trim();
                  if (name.isNotEmpty && selectedUserIds.isNotEmpty) {
                    await _createChatRoom(name, selectedUserIds);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero, // Remove padding to allow gradient to fill
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.purpleAccent],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: const Text("Create", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
            );
          },
        );
      },
    );
  }

  Future<void> _createChatRoom(String name, List<String> participants) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      participants.add(currentUser.uid);
    }

    final now = DateTime.now();
    final chatRoomRef = FirebaseFirestore.instance.collection('ChatRoom').doc();

    await chatRoomRef.set({
      'id': chatRoomRef.id,
      'name': name,
      'createdBy': currentUser!.uid,
      'createdOn': now,
      'updatedBy': currentUser.uid,
      'updatedOn': now,
      'participants': participants,
    });
  }
}