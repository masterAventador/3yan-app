import 'package:sanyan_network/sanyan_network.dart';
import 'message_status.dart';

class Message {
  final int id;
  final String senderType;
  final String content;
  final String createdAt;
  // client-only：本地发送跟踪
  final String? clientMsgId;
  MessageStatus? status;

  Message({
    required this.id,
    required this.senderType,
    required this.content,
    required this.createdAt,
    this.clientMsgId,
    this.status,
  });

  bool get isFromAi => senderType == SenderType.ai;
  bool get isSending => status == MessageStatus.sending;
  bool get isFailed => status == MessageStatus.failed;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] ?? 0,
    senderType: json['senderType'] ?? '',
    content: json['content'] ?? '',
    createdAt: json['createdAt'] ?? '',
  );
}
