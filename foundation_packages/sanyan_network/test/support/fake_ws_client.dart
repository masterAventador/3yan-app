import 'dart:async';
import 'package:sanyan_network/sanyan_network.dart';

/// WsClient 是 GetxService，mocktail 不工作（onStart 的 InternalFinalCallback
/// 为 null）。这个 fake 暴露测试需要的事件流和 send 方法调用记录。
/// 后续 task（T7 ACK、T8 timeout、T9 disconnect）会继续扩展。
class FakeWsClient extends WsClient {
  final StreamController<WsEvent> _events = StreamController.broadcast();
  final StreamController<void> _disconnected = StreamController.broadcast();
  final sentTexts = <Map<String, dynamic>>[];
  final sentVoices = <Map<String, dynamic>>[];

  @override
  Stream<WsEvent> get eventStream => _events.stream;

  @override
  Stream<void> get onDisconnected => _disconnected.stream;

  @override
  void sendMessage({
    required int conversationId,
    required String content,
    required String clientMsgId,
    String contentType = ContentType.text,
  }) {
    sentTexts.add({
      'conversationId': conversationId,
      'content': content,
      'clientMsgId': clientMsgId,
    });
  }

  @override
  void sendVoiceMessage({
    required int conversationId,
    required String mediaUrl,
    required int duration,
    required String clientMsgId,
  }) {
    sentVoices.add({
      'conversationId': conversationId,
      'mediaUrl': mediaUrl,
      'duration': duration,
      'clientMsgId': clientMsgId,
    });
  }

  /// 测试辅助：模拟收到 ACK（注入 WsEvent 到事件流）
  void simulateAck(String clientMsgId) {
    _events.add(WsEvent(type: WsEventType.ack, clientMsgId: clientMsgId));
  }

  /// 测试辅助：模拟断开
  void simulateDisconnect() {
    _disconnected.add(null);
  }

  void disposeForTest() {
    _events.close();
    _disconnected.close();
  }
}
