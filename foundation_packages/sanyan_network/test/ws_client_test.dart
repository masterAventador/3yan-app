import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_network/sanyan_network.dart';

void main() {
  test('should parse new_message event', () {
    final event = WsEvent.fromJson({
      'type': 'new_message',
      'message': {
        'id': 50002,
        'senderType': 'ai',
        'content': '你好呀',
        'createdAt': '2026-04-07 20:30:15',
      }
    });
    expect(event.type, 'new_message');
    expect(event.message, isNotNull);
    expect(event.message!['content'], '你好呀');
  });

  test('should parse ack event', () {
    final event = WsEvent.fromJson({
      'type': 'ack',
      'clientMsgId': 'uuid-123',
    });
    expect(event.type, 'ack');
    expect(event.clientMsgId, 'uuid-123');
  });

  test('should parse typing event', () {
    final event = WsEvent.fromJson({'type': 'typing'});
    expect(event.type, 'typing');
  });
}
