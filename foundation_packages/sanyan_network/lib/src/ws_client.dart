import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

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
  static const _maxReconnectAttempts = 10;
  static const _uuid = Uuid();

  final _eventController = StreamController<WsEvent>.broadcast();
  Stream<WsEvent> get eventStream => _eventController.stream;

  final isConnected = false.obs;

  /// Set this to provide the auth token for WebSocket connections.
  static WsTokenProvider? tokenProvider;

  void connect() {
    final token = tokenProvider?.call();
    if (token == null) return;

    try {
      final uri = Uri.parse('${AppConstants.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (e) => _onDisconnected(),
      );

      _isConnected = true;
      isConnected.value = true;
      _reconnectAttempts = 0;
      _startHeartbeat();
      syncMessages();
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    isConnected.value = false;
  }

  String sendMessage(int conversationId, String content, {String contentType = 'text'}) {
    final clientMsgId = _uuid.v4();
    _send({
      'type': 'send_message',
      'conversationId': conversationId,
      'contentType': contentType,
      'content': content,
      'clientMsgId': clientMsgId,
    });
    return clientMsgId;
  }

  void syncMessages({int lastMsgId = 0}) {
    _send({'type': 'sync', 'lastMsgId': lastMsgId});
  }

  void _send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['type'] == 'pong') return;
      _eventController.add(WsEvent.fromJson(json));
    } catch (e) {
      // ignore malformed messages
    }
  }

  void _onDisconnected() {
    _isConnected = false;
    isConnected.value = false;
    _heartbeatTimer?.cancel();
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send({'type': 'ping'});
    });
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
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
