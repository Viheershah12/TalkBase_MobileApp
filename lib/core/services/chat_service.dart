import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/chat_room.dart';
import '../constants.dart';

class ChatService {
  final String token; // Inject via constructor or a provider
  final String tenant;

  ChatService(this.token, this.tenant);

  Future<List<ChatRoom>> getChatRooms() async {
    final uri = Uri.parse('${AppConstants.chatApiBaseUrl}/chatRoom/getList');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        '__tenant': tenant,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;
      return items.map((item) => ChatRoom.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load chat rooms');
    }
  }
}