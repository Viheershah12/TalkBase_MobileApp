import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../core/services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  ChatService? _chatService;

  List<ChatRoom> _chatRooms = [];
  bool _isLoading = false;

  List<ChatRoom> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;

  // Call this after login to inject a proper ChatService
  void initialize(ChatService chatService) {
    _chatService = chatService;
    notifyListeners();
  }

  Future<void> loadChatRooms() async {
    if (_chatService == null) {
      debugPrint('ChatService is not initialized');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _chatRooms = await _chatService!.getChatRooms();
    } catch (e) {
      debugPrint('Failed to fetch chat rooms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
