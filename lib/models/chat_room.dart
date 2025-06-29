class ChatRoom {
  final String id;
  final String name;
  final String createdBy;
  final DateTime? createdOn;
  final DateTime? updatedOn;
  final String updatedBy;
  final List<String> participants;
  final Map<String, int> unreadCounts;

  ChatRoom({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdOn,
    required this.updatedBy,
    required this.updatedOn,
    required this.participants,
    this.unreadCounts = const {},
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdOn: map['createdOn']?.toDate(),
      updatedBy: map['updatedBy'] ?? '',
      updatedOn: map['updatedOn']?.toDate(),
      participants: List<String>.from(map['participants'] ?? []),
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'createdOn': createdOn,
      'updatedBy': updatedBy,
      'updatedOn': updatedOn,
      'participants': participants,
    };
  }
}
