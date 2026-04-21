import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'app_constants.dart';
import 'content_type.dart' as ct;
import 'ws_event_type.dart';

/// Provides the token for WebSocket connections.
/// Must be set before calling [WsClient.connect].
typedef WsTokenProvider = String? Function();

class WsEvent {
  final String type;
  final int? conversationId;
  final Map<String, dynamic>? message;
  final String? clientMsgId;
  final int? serverMsgId;
  final List<dynamic>? messages;
  final bool? hasMore;

  WsEvent({
    required this.type, this.conversationId, this.message,
    this.clientMsgId, this.serverMsgId, this.messages, this.hasMore,
  });

  factory WsEvent.fromJson(Map<String, dynamic> json) => WsEvent(
    type: json['type'] ?? '',
    conversationId: json['conversationId'] ??
        (json['message'] is Map ? json['message']['conversationId'] : null),
    message: json['message'] is Map<String, dynamic> ? json['message'] : null,
    clientMsgId: json['clientMsgId'],
    serverMsgId: json['serverMsgId'],
    messages: json['messages'],
    hasMore: json['hasMore'],
  );
}

class WsClient extends GetxService {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const _uuid = Uuid();

  /// 指数退避重连延迟序列：1s, 2s, 5s, 10s, 30s（之后一直 30s）。
  static Duration reconnectDelayForAttempt(int attempt) {
    const sequence = [1, 2, 5, 10, 30];
    final idx = attempt < sequence.length ? attempt : sequence.length - 1;
    return Duration(seconds: sequence[idx]);
  }

  final _eventController = StreamController<WsEvent>.broadcast();
  Stream<WsEvent> get eventStream => _eventController.stream;

  final _disconnectedController = StreamController<void>.broadcast();

  /// 被动断开事件流：当底层 WebSocket 从连接状态转为断开时 fire。
  ///
  /// 触发路径：
  ///   - stream `onDone`（对端关闭）
  ///   - stream `onError`（IO 错误）
  ///   - `_send` 时 sink 已关（写失败）
  ///   - `connect()` 内 `runZonedGuarded` 捕获异常
  ///
  /// 订阅方（例如 MessageSender）用这个把 pending 消息标 failed。
  /// 注意：主动调用 [disconnect] **不**触发此事件——主动断开时通常是
  /// 应用退出流程，pending 消息的处理由 onClose 统一负责。
  Stream<void> get onDisconnected => _disconnectedController.stream;

  @visibleForTesting
  void notifyDisconnectedForTest() => _disconnectedController.add(null);

  final isConnected = false.obs;

  /// Set this to provide the auth token for WebSocket connections.
  static WsTokenProvider? tokenProvider;

  void connect() {
    // 先清理旧连接，防止重复监听
    _cleanup();

    final token = tokenProvider?.call();
    if (token == null) return;

    final uri = Uri.parse('${AppConstants.wsUrl}?token=$token');
    _logConnect(uri);

    // 使用 runZonedGuarded 捕获所有同步和异步异常
    runZonedGuarded(() {
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: true,
      );

      _isConnected = true;
      isConnected.value = true;
      _reconnectAttempts = 0;
      _startHeartbeat();
      syncMessages();
    }, (error, stack) {
      // 连接失败或 stream 抛出的任何异常都不会让 app 崩溃
      _logConnectError(error);
      _onDisconnected();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _cleanup();
  }

  /// 清理连接资源，不触发重连
  void _cleanup() {
    _heartbeatTimer?.cancel();
    _isConnected = false;
    isConnected.value = false;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  String sendMessage(int conversationId, String content, {String contentType = ct.ContentType.text}) {
    final clientMsgId = _uuid.v4();
    _send({
      'type': WsEventType.sendMessage,
      'conversationId': conversationId,
      'contentType': contentType,
      'content': content,
      'clientMsgId': clientMsgId,
    });
    return clientMsgId;
  }

  String sendVoiceMessage({
    required int conversationId,
    required String mediaUrl,
    required int duration,
    String? clientMsgId,
  }) {
    final msgId = clientMsgId ?? _uuid.v4();
    _send({
      'type': WsEventType.sendMessage,
      'conversationId': conversationId,
      'contentType': ct.ContentType.voice,
      'content': '',
      'mediaUrl': mediaUrl,
      'duration': duration,
      'clientMsgId': msgId,
    });
    return msgId;
  }

  void syncMessages({int lastMsgId = 0}) {
    _send({'type': WsEventType.sync, 'lastMsgId': lastMsgId});
  }

  void _send(Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) return;
    try {
      final payload = jsonEncode(data);
      _channel!.sink.add(payload);
      _logSend(data);
    } catch (e) {
      // sink 已关闭，触发重连
      _onDisconnected();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['type'] == WsEventType.pong) return;
      _logReceive(json);
      _eventController.add(WsEvent.fromJson(json));
    } catch (e) {
      // ignore malformed messages
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 日志输出
  // ─────────────────────────────────────────────────────────────

  void _logConnect(Uri uri) {
    if (!kDebugMode) return;
    final buf = StringBuffer();
    buf.writeln('\n╔══════════════════════════════════════════════════════════════');
    buf.writeln('║ 🔌 WS CONNECT');
    buf.writeln('║ URL: $uri');
    buf.writeln('╚══════════════════════════════════════════════════════════════');
    developer.log(buf.toString(), name: 'WS');
  }

  void _logConnectError(Object error) {
    if (!kDebugMode) return;
    final buf = StringBuffer();
    buf.writeln('\n╔══════════════════════════════════════════════════════════════');
    buf.writeln('║ ❌ WS CONNECT FAILED');
    buf.writeln('║ Error: $error');
    buf.writeln('║ 重连次数: $_reconnectAttempts');
    buf.writeln('╚══════════════════════════════════════════════════════════════');
    developer.log(buf.toString(), name: 'WS');
  }

  void _logSend(Map<String, dynamic> data) {
    if (!kDebugMode) return;
    // ping 太频繁，跳过
    if (data['type'] == WsEventType.ping) return;
    final buf = StringBuffer();
    buf.writeln('\n╔══════════════════════════════════════════════════════════════');
    buf.writeln('║ 🔺 WS SEND');
    buf.writeln('║ Type: ${data['type']}');
    buf.writeln('╠══════════════════════════════════════════════════════════════');
    buf.writeln(_prettyJson(data));
    buf.writeln('╚══════════════════════════════════════════════════════════════');
    developer.log(buf.toString(), name: 'WS');
  }

  void _logReceive(Map<String, dynamic> data) {
    if (!kDebugMode) return;
    final buf = StringBuffer();
    buf.writeln('\n╔══════════════════════════════════════════════════════════════');
    buf.writeln('║ 🔻 WS RECV');
    buf.writeln('║ Type: ${data['type']}');
    buf.writeln('╠══════════════════════════════════════════════════════════════');
    buf.writeln(_prettyJson(data));
    buf.writeln('╚══════════════════════════════════════════════════════════════');
    developer.log(buf.toString(), name: 'WS');
  }

  String _prettyJson(dynamic data) {
    final raw = () {
      if (data == null) return 'null';
      try {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(data);
      } catch (_) {
        return data.toString();
      }
    }();
    return raw.split('\n').map((line) => '║ $line').join('\n');
  }

  void _onDisconnected() {
    if (!_isConnected && _channel == null) return; // 已经处理过了
    _cleanup();
    _scheduleReconnect();
    _disconnectedController.add(null);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send({'type': WsEventType.ping});
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = reconnectDelayForAttempt(_reconnectAttempts);
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect();
    });
  }

  @override
  void onClose() {
    disconnect();
    _eventController.close();
    _disconnectedController.close();
    super.onClose();
  }
}
