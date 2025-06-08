class ChatParticipant {
  final String id;
  final String chatRoomId;
  final String userId;
  final DateTime joinedAt;
  final bool isAdmin;
  final bool isOnline;

  ChatParticipant({
    required this.id,
    required this.chatRoomId,
    required this.userId,
    required this.joinedAt,
    required this.isAdmin,
    required this.isOnline,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'],
      chatRoomId: json['chatRoomId'],
      userId: json['userId'],
      joinedAt: DateTime.parse(json['joinedAt']),
      isAdmin: json['isAdmin'],
      isOnline: json['isOnline'],
    );
  }
}