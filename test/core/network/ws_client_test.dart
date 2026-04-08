import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_app/core/network/ws_client.dart';

void main() {
  test('should parse new_message event', () {
    final json = {
      'type': 'new_message',
      'conversationId': 100,
      'message': {
        'id': 50002,
        'senderType': 'ai',
        'contentType': 'text',
        'content': '你好呀',
        'source': 'reply',
        'createdAt': '2026-04-07 20:30:15',
      }
    };

    final event = WsEvent.fromJson(json);
    expect(event.type, 'new_message');
    expect(event.conversationId, 100);
    expect(event.message, isNotNull);
    expect(event.message!['content'], '你好呀');
  });

  test('should parse ack event', () {
    final event = WsEvent.fromJson({
      'type': 'ack',
      'clientMsgId': 'uuid-123',
      'serverMsgId': 50001,
    });

    expect(event.type, 'ack');
    expect(event.clientMsgId, 'uuid-123');
  });

  test('should parse typing event', () {
    final event = WsEvent.fromJson({
      'type': 'typing',
      'conversationId': 100,
    });

    expect(event.type, 'typing');
    expect(event.conversationId, 100);
  });
}
