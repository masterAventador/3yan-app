/// 发送中消息的追踪条目（MessageSender 内部使用）。
///
/// **架构约束**：不直接持有 Message 对象引用——Message 类在
/// sanyan_chat (business package) 中，sanyan_network (foundation) 不能反向
/// 依赖 business 层。存消息内容的 Map<String, dynamic> 快照，sanyan_chat
/// 侧负责把 messageJson 解析回 Message。
///
/// 字段：
/// - [clientMsgId]: 客户端生成的消息 id，Sender / WsClient / 服务端 ACK 之间
///   的追踪锚点。
/// - [conversationId]: 所属会话 id，用于按会话过滤 pending 消息（getPending）。
/// - [sendTimeMs]: 发送时刻（`DateTime.now().millisecondsSinceEpoch`），
///   周期扫描判超时用 `now - sendTimeMs > timeout`。
/// - [messageJson]: 消息内容快照，ChatController 会 `Message.fromJson` 回来
///   展示给 UI；也用于持久化到 GetStorage 跨冷启生存。
class PendingEntry {
  final String clientMsgId;
  final int conversationId;
  final int sendTimeMs;
  final Map<String, dynamic> messageJson;

  PendingEntry({
    required this.clientMsgId,
    required this.conversationId,
    required this.sendTimeMs,
    required this.messageJson,
  });

  Map<String, dynamic> toJson() => {
        'clientMsgId': clientMsgId,
        'conversationId': conversationId,
        'sendTimeMs': sendTimeMs,
        'message': messageJson,
      };

  factory PendingEntry.fromJson(Map<String, dynamic> json) => PendingEntry(
        clientMsgId: json['clientMsgId'] as String,
        conversationId: json['conversationId'] as int,
        sendTimeMs: json['sendTimeMs'] as int,
        messageJson: Map<String, dynamic>.from(json['message'] as Map),
      );
}
