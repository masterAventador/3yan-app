import 'package:sanyan_network/sanyan_network.dart';

class Message {
  final int id;
  final int conversationId;
  final String senderType;
  final String contentType;
  final String content;
  final String? mediaUrl;
  final String source;
  final String createdAt;
  final String? clientMsgId;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.contentType,
    required this.content,
    this.mediaUrl,
    required this.source,
    required this.createdAt,
    this.clientMsgId,
  });

  bool get isFromAi => senderType == 'ai';
  bool get isProactive => source == 'proactive';
  bool get isVoice => contentType == ContentType.voice && mediaUrl != null;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] ?? 0,
    conversationId: json['conversationId'] ?? 0,
    senderType: json['senderType'] ?? '',
    contentType: json['contentType'] ?? 'text',
    content: json['content'] ?? '',
    mediaUrl: json['mediaUrl'],
    source: json['source'] ?? 'reply',
    createdAt: json['createdAt'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderType': senderType,
    'contentType': contentType,
    'content': content,
    'mediaUrl': mediaUrl,
    'source': source,
    'createdAt': createdAt,
  };
}
