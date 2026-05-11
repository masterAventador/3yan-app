import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'app_constants.dart';
import 'ws_event_type.dart';

typedef WsTokenProvider = String? Function();

class WsEvent {
  final String type;
  final Map<String, dynamic>? message;
  final String? clientMsgId;
  final int? serverMsgId;
  final List<dynamic>? messages;

  WsEvent({required this.type, this.message, this.clientMsgId, this.serverMsgId, this.messages});

  factory WsEvent.fromJson(Map<String, dynamic> json) => WsEvent(
    type: json['type'] ?? '',
    message: json['message'] is Map<String, dynamic> ? json['message'] : null,
    clientMsgId: json['clientMsgId'],
    serverMsgId: json['serverMsgId'],
    messages: json['messages'],
  );
}

class WsClient extends GetxService {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;

  /// 指数退避重连延迟序列：1s, 2s, 5s, 10s, 30s（之后一直 30s）。
  static Duration reconnectDelayForAttempt(int attempt) {
    const sequence = [1, 2, 5, 10, 30];
    final idx = attempt < sequence.length ? attempt : sequence.length - 1;
    return Duration(seconds: sequence[idx]);
  }

  final _eventController = StreamController<WsEvent>.broadcast();
  Stream<WsEvent> get eventStream => _eventController.stream;

  final isConnected = false.obs;

  static WsTokenProvider? tokenProvider;

  Future<void> connect() async {
    _cleanup();

    final token = tokenProvider?.call();
    if (token == null) return;

    final uri = Uri.parse('${AppConstants.wsUrl}?token=$token');
    _logConnect(uri);

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

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
    } catch (error) {
      _logConnectError(error);
      _onDisconnected();
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _cleanup();
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _isConnected = false;
    isConnected.value = false;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void sendMessage({required String content, required String clientMsgId}) {
    _send({
      'type': WsEventType.sendMessage,
      'content': content,
      'clientMsgId': clientMsgId,
    });
  }

  void syncMessages({int lastMsgId = 0}) {
    _send({'type': WsEventType.sync, 'lastMsgId': lastMsgId});
  }

  void _send(Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(data));
      _logSend(data);
    } catch (e) {
      _onDisconnected();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['type'] == WsEventType.pong) return;
      _logReceive(json);
      _eventController.add(WsEvent.fromJson(json));
    } catch (_) {
      // 忽略畸形消息
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 日志
  // ─────────────────────────────────────────────────────────────

  void _logConnect(Uri uri) {
    if (!kDebugMode) return;
    final buf = StringBuffer();
    buf.writeln('\n╔══════════════════════════════════════════════════════════════');
    buf.writeln('║ 🔌 WS CONNECT');
    buf.writeln('║ URL: $uri');
    buf.writeln('╚══════════════════════════════════════════════════════════════');
    debugPrint('[WS]${buf.toString()}');
  }

  void _logConnectError(Object error) {
    if (!kDebugMode) return;
    final buf = StringBuffer();
    buf.writeln('\n╔══════════════════════════════════════════════════════════════');
    buf.writeln('║ ❌ WS CONNECT FAILED');
    buf.writeln('║ Error: $error');
    buf.writeln('║ 重连次数: $_reconnectAttempts');
    buf.writeln('╚══════════════════════════════════════════════════════════════');
    debugPrint('[WS]${buf.toString()}');
  }

  void _logSend(Map<String, dynamic> data) {
    if (!kDebugMode) return;
    if (data['type'] == WsEventType.ping) return;
    final buf = StringBuffer();
    buf.writeln('\n╔══════════════════════════════════════════════════════════════');
    buf.writeln('║ 🔺 WS SEND  Type: ${data['type']}');
    buf.writeln('╠══════════════════════════════════════════════════════════════');
    buf.writeln(_prettyJson(data));
    buf.writeln('╚══════════════════════════════════════════════════════════════');
    debugPrint('[WS]${buf.toString()}');
  }

  void _logReceive(Map<String, dynamic> data) {
    if (!kDebugMode) return;
    final buf = StringBuffer();
    buf.writeln('\n╔══════════════════════════════════════════════════════════════');
    buf.writeln('║ 🔻 WS RECV  Type: ${data['type']}');
    buf.writeln('╠══════════════════════════════════════════════════════════════');
    buf.writeln(_prettyJson(data));
    buf.writeln('╚══════════════════════════════════════════════════════════════');
    debugPrint('[WS]${buf.toString()}');
  }

  String _prettyJson(dynamic data) {
    final raw = () {
      if (data == null) return 'null';
      try {
        return const JsonEncoder.withIndent('  ').convert(data);
      } catch (_) {
        return data.toString();
      }
    }();
    return raw.split('\n').map((line) => '║ $line').join('\n');
  }

  void _onDisconnected() {
    if (!_isConnected && _channel == null) return;
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
    super.onClose();
  }
}
