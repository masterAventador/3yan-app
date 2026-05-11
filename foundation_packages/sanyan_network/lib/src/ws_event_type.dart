abstract class WsEventType {
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String sendMessage = 'send_message';
  static const String newMessage = 'new_message';
  static const String typing = 'typing';
  static const String ack = 'ack';
  static const String sync = 'sync';
  static const String syncResult = 'sync_result';
}
