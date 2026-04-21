import 'package:sanyan_network/sanyan_network.dart';
import 'message_status.dart';

class Message {
  final int id;
  final int conversationId;
  final String senderType;
  final String contentType;
  final String content;
  String? mediaUrl;
  final String source;
  final String createdAt;
  final String? clientMsgId;
  final int? duration;
  // 降级原因：asr_failed（ASR 识别失败）/ tts_failed（TTS 合成失败）/ null（正常）。
  // 服务端开启了 Jackson non_null 过滤，正常消息该字段不会出现在响应里。
  final String? fallbackReason;
  MessageStatus? status;
  String? localFilePath;

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
    this.duration,
    this.fallbackReason,
    this.status,
    this.localFilePath,
  });

  bool get isFromAi => senderType == SenderType.ai;
  bool get isProactive => source == 'proactive';
  // 只看 contentType 就够了。mediaUrl 为 null 时（刚发送、上传中）也该走语音 bubble，
  // 否则会短暂降级成空文字 bubble，视觉上是一个只有 padding 的小方块。
  // VoiceBubble 内部有 localFilePath 兜底播放，不需要 mediaUrl 才能渲染。
  bool get isVoice => contentType == ContentType.voice;
  bool get isSending => status == MessageStatus.sending;
  bool get isFailed => status == MessageStatus.failed;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] ?? 0,
    conversationId: json['conversationId'] ?? 0,
    senderType: json['senderType'] ?? '',
    contentType: json['contentType'] ?? ContentType.text,
    content: json['content'] ?? '',
    mediaUrl: json['mediaUrl'],
    source: json['source'] ?? 'reply',
    createdAt: json['createdAt'] ?? '',
    duration: json['duration'],
    fallbackReason: json['fallbackReason'],
    clientMsgId: json['clientMsgId'],
    status: _parseStatus(json['status'] as String?),
  );

  // MessageStatus enum 的 name 和 MessageWireStatus 的字符串常量对齐
  // （sending/sent/failed），解析失败（null 或未知值）统一返回 null。
  static MessageStatus? _parseStatus(String? raw) {
    if (raw == null) return null;
    for (final s in MessageStatus.values) {
      if (s.name == raw) return s;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderType': senderType,
    'contentType': contentType,
    'content': content,
    'mediaUrl': mediaUrl,
    'source': source,
    'createdAt': createdAt,
    'duration': duration,
    'fallbackReason': fallbackReason,
    'clientMsgId': clientMsgId,
    'status': status?.name,
  };
}
