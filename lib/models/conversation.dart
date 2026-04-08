class Conversation {
  final int id;
  final int characterId;
  final String? characterName;
  final String? characterAvatar;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.characterId,
    this.characterName,
    this.characterAvatar,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'],
    characterId: json['characterId'],
    characterName: json['characterName'],
    characterAvatar: json['characterAvatar'],
    lastMessage: json['lastMessage'],
    lastMessageAt: json['lastMessageAt'],
    unreadCount: json['unreadCount'] ?? 0,
  );
}
