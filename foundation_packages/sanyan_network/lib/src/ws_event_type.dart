abstract class WsEventType {
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String sendMessage = 'send_message';
  static const String newMessage = 'new_message';
  static const String typing = 'typing';
  static const String ack = 'ack';
  static const String sync = 'sync';
  static const String syncResult = 'sync_result';

  // ── 亲密度 / 阶段相关推送帧 ──
  static const String intimacyUpdate = 'intimacy_update';
  static const String stageTransition = 'stage_transition';
  static const String stageStory = 'stage_story';
}
