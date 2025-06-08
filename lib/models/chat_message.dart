class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String? message;
  final DateTime sentAt;
  final bool isEdited;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.message,
    required this.sentAt,
    required this.isEdited,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatRoomId: json['chatRoomId'],
      senderId: json['senderId'],
      message: json['message'],
      sentAt: DateTime.parse(json['sentAt']),
      isEdited: json['isEdited'],
    );
  }
}