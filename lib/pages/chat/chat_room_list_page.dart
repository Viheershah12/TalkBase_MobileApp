import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_room_tile.dart';

class ChatRoomListPage extends StatefulWidget {
  const ChatRoomListPage({super.key});

  @override
  State<ChatRoomListPage> createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends State<ChatRoomListPage> {
  @override
  void initState() {
    super.initState();
    Provider.of<ChatProvider>(context, listen: false).loadChatRooms();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms'),
        backgroundColor: Colors.deepPurple,
        titleTextStyle: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w500,
            fontSize: 20
        )
      ),
      body: RefreshIndicator(
        onRefresh: () => chatProvider.loadChatRooms(),
        child: chatProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : chatProvider.chatRooms.isEmpty
              ? const Center(child: Text("No chat rooms found."))
              : ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: chatProvider.chatRooms.length,
            itemBuilder: (context, index) =>
                ChatRoomTile(chatRoom: chatProvider.chatRooms[index]),
        ),
      ),
    );
  }
}
