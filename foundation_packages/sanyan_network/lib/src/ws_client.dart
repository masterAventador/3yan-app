import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
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
  static const _maxReconnectAttempts = 20;
  static const _uuid = Uuid();

  final _eventController = StreamController<WsEvent>.broadcast();
  Stream<WsEvent> get eventStream => _eventController.stream;

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
    buf.writeln('║ 重连次数: $_reconnectAttempts / $_maxReconnectAttempts');
    buf.writeln('╚══════════════════════════════════════════════════════════════');
    developer.log(buf.toString(), name: 'WS');
  }

  void _logSend(Map<String, dynamic> data) {
    if (!kDebugMode) return;
    // ping 太频繁，跳过
    if (data['type'] == WsEventType.ping) return;
    final buf = StringBuffer();
    buf.writeln('\n╔══════════════════════════════════════════════════════════════');
    buf.writeln('║ ⬆️  WS SEND');
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
    buf.writeln('║ ⬇️  WS RECV');
    buf.writeln('║ Type: ${data['type']}');
    buf.writeln('╠══════════════════════════════════════════════════════════════');
    buf.writeln(_prettyJson(data));
    buf.writeln('╚══════════════════════════════════════════════════════════════');
    developer.log(buf.toString(), name: 'WS');
  }

  String _prettyJson(dynamic data) {
    if (data == null) return 'null';
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  void _onDisconnected() {
    if (!_isConnected && _channel == null) return; // 已经处理过了
    _cleanup();
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send({'type': WsEventType.ping});
    });
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      // 达到上限后重置计数，延迟 60 秒再试，永不放弃
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 60), () {
        connect();
      });
      return;
    }
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: 2 * (_reconnectAttempts + 1));
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect();
    });
  }

  @override
  void onClose() {
    disconnect();
    _eventController.close();
    super.onClose();
  }
}
