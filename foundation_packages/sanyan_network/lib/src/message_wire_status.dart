/// 消息发送状态的 wire value 常量（跨 MessageSender / ChatController /
/// GetStorage 持久化 / Message.toJson 统一使用，防止字面量散落）。
///
/// 对应 `sanyan_chat` 的 `MessageStatus` enum（name 属性恰好是同样的
/// 字符串），两边互为 wire ↔ enum 的约定。
abstract class MessageWireStatus {
  static const String sending = 'sending';
  static const String sent = 'sent';
  static const String failed = 'failed';

  const MessageWireStatus._();
}
